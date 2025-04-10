use strict;
use warnings;

use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use File::Spec::Functions 'catfile';
use File::Copy;
use File::Slurp qw(read_file);
use File::Temp qw/ tempfile tempdir /;

use Getopt::Long;
use JSON;

my $root_dir = dirname(abs_path($0));
my $server_dir = catfile($root_dir, "server");
my $client_dir = catfile($root_dir, "web");
my $webapp_dir = catfile($server_dir, "src", "main", "resources", "static", "app");
my $deploy_dir = catfile($root_dir, "infrastructure");
my $amplify_configuration_file = catfile($root_dir, "mobile", "lib", "amplifyconfiguration.json");

my $compile_webapp = -1;
my $compile_server = 1;
my $build_docker_image = 1;
my $update_load_balancer_dns = 1;

my $alternate_cdk_json_path = "";
my $cdkConfig = "";

my $show_help = 0;
our @context_variables = ();

GetOptions('webapp!' => \$compile_webapp, 'server!' => \$compile_server, 
    'update-dns!' => \$update_load_balancer_dns, 'cdk-config=s' => \$alternate_cdk_json_path,
    'build_docker_image!' => \$build_docker_image, 'context=s@' => \@context_variables, 'help' => \$show_help);

if ($show_help) {
    print "Usage: perl deploy.pl [--no-webapp] [--no-server] [--no-build_docker_image] [--no-update-dns] [--help]\n\n";
    print "Both the management web application and the backend API server will be built by default\n";
    print "Use the --nowebapp and --no-server options to use an existing compiled version of those components\n";
    exit (0);
}

if ($alternate_cdk_json_path) {
    $cdkConfig = read_alternate_cdk_json_file($alternate_cdk_json_path);
}

sub read_alternate_cdk_json_file($) {
    my ($path) = @_;

    my $json_text = read_file($path);
    my $json_output = decode_json($json_text);

    return $json_output;
}

sub read_value_from_cdk_json ($) {
    my ($variableName) = @_;

    #  Override values in cdk.json with those specified on the command line 
    #  if present
    my @values = grep (/$variableName/, @context_variables);

    if (@values > 1) {
        print STDERR "The value for $variableName was passed multiple times using --context; this is not allowed\n";
        exit(1);
    }
    elsif (@values == 1) {                
        if ($values[0] =~ /.*=(.*)/) {
            return $1;
        }
        else {
            print STDERR "Values passed for --context arguments should be in the form name=value\n";
            print STDERR "You passed: $values[0]\n";
            exit(1);
        }
    }

    # Override values in cdk.json if they are present in the alternate config file
    if ($cdkConfig && exists($cdkConfig->{$variableName})) {
        return $cdkConfig->{$variableName};
    }

    my $cdk_json_path = catfile($deploy_dir, "cdk.json");
    open (my $cdk_json_file, $cdk_json_path)
        or die "Cannot open $cdk_json_path to read $variableName";

    chomp (my @lines = <$cdk_json_file>);
    my @desiredLines = grep /"$variableName\s*":/, @lines;
    if (@desiredLines == 0) {
        die "Could not find $variableName line in $cdk_json_path";
    }
    if (@desiredLines > 1) {
        die "There are multiple $variableName lines in $cdk_json_path";
    }

    unless ($desiredLines[0] =~ /"$variableName\s*":\s*"?([^"]+)"?/) {
        die "context line $desiredLines[0] does not match expected pattern to read $variableName";
    }

    my $value = $1;
    $value =~ s/,$//;
    if ($value eq "default") {
        print STDERR "The value of the property $variableName in cdk.json is still set to \"default\"\n";
        print STDERR "You must change this to the appropriate value\n";
        exit(1);
    }
    return $value;
}

if  ($compile_webapp == -1) {
    $compile_webapp = read_value_from_cdk_json("compile.webapp");
    $compile_webapp = $compile_webapp == 0 || $compile_webapp eq "false" ? 0 : 1;
}

my $accountId = read_value_from_cdk_json("accountId");
my $region = read_value_from_cdk_json("region");
my $awsProfile =  read_value_from_cdk_json("awsProfile");

my $applicationName = read_value_from_cdk_json("applicationName");

sub compile_webapp () {
    chdir ($client_dir)
        or die "Could not change directories to the webapp folder ($client_dir)";
    
    my $flutter_cmd = "flutter build web --output $webapp_dir --base-href /app/";

    print "Compiling web application to $webapp_dir ...";

    `$flutter_cmd`;
    unless ($? == 0) {
        die "Failed to compile webapp project"
    }

    print "Success\n";
}

sub compile_server () {
    chdir ($server_dir)
        or die "Could not change directories to the server folder ($server_dir)";

    print "Compiling api server project to $server_dir ... ";

    my $output = `mvn package -DskipTests=true`;
    die ("Failed to compile server: $output") unless $? == 0;

    print "Success\n";
}

sub log_into_ecr () {    
    my $login_cmd = "aws ecr get-login-password --region $region --profile $awsProfile | docker login --username AWS --password-stdin $accountId.dkr.ecr.$region.amazonaws.com/$applicationName";

    print "Logging in to ECR repository ... ";
    `$login_cmd`;
    if ($? != 0) {
        die ("Failed to log in to ECR repository");
    }
    print "Success\n";
}

sub get_next_image_tag {
    print "Retrieving existing docker image tags from ECR repository ...";

    my $applicationName = read_value_from_cdk_json("applicationName");
    my $region = read_value_from_cdk_json("region");
    my $awsProfile = read_value_from_cdk_json("awsProfile");
    
    my $list_remote_images_cmd = "aws ecr list-images --repository-name $applicationName --region $region --profile $awsProfile";
    my $list_remote_images_output = `$list_remote_images_cmd`;
    if ($? != 0) {
        die "\nFailed to list images in remote AWS ECR repository using command: $list_remote_images_cmd";
    }
    
    my $json = decode_json($list_remote_images_output);
    my @imageTags = sort {$b <=> $a} map { $_->{imageTag} } @{$json->{imageIds}};   

    print (" Success\n");
    return @imageTags == 0 ? 1 : $imageTags[0]+1;
}

sub delete_existing_docker_image {
    my ($tag) = @_;

    my $applicationName = read_value_from_cdk_json("applicationName");
    my $region = read_value_from_cdk_json("region");
    my $awsProfile = read_value_from_cdk_json("awsProfile");
    
    print "Deleting existing docker image with tag $tag from ECR repository ... ";

    my $delete_image_cmd = "aws ecr batch-delete-image --repository-name $applicationName --image-ids imageTag=$tag --region $region --profile $awsProfile";
    my $delete_image_output = `$delete_image_cmd`;
    if ($? != 0) {
        die "\nFailed to delete docker image with tag $tag using command: $delete_image_cmd\n$delete_image_output\n";
    }
    print "Success\n";

    print "Deleting existing docker image with tag $tag from local Docker repository ... ";
    my $delete_local_image_cmd = "docker rmi $accountId.dkr.ecr.$region.amazonaws.com/$applicationName:$tag";
    my $delete_local_image_output = `$delete_local_image_cmd`;
    if ($? != 0) {
        print "\nFailed to delete local docker image with tag $tag using command: $delete_local_image_cmd\n$delete_local_image_output\nVerify Docker is running\n";
    }
    print "Success\n";
}

sub build_and_push_docker_image {
    my ($build_docker_image) = @_;

    my $tag = get_next_image_tag();
        
    if ($build_docker_image) {
        print "Building docker image with tag $tag ... ";
        chdir ($server_dir) or die "Cannot change directories to $server_dir";

        my $docker_image_with_tag = "$accountId.dkr.ecr.$region.amazonaws.com/$applicationName:$tag";
        my $build_image_command = "docker build -t $docker_image_with_tag .";
        `$build_image_command`;
        if ($? != 0) {
            die "Failed to build local docker image using command\n$build_image_command";
        }

        print "Success\n";

        print "Pushing docker image to ECR repository ... ";
        my $push_image_command = "docker push $docker_image_with_tag";
        `$push_image_command`;

        if ($? != 0) {
            die "Failed to push image to using command $push_image_command";
        }

        print "Done\n";        
    }
    else {
        $tag -= 1;
    }
    return $tag;
}

sub build_foundation_stack() {
    chdir($deploy_dir);
    my $cdk_command = "cdk deploy FoundationStack --context dockerImageTag=latest --profile $awsProfile --require-approval never";

    for my $context_argument (@main::context_variables) {
        $cdk_command .= " --context $context_argument";    
    }

    print "Building foundation stack ... ";
    my $output = `$cdk_command`;

    if ($? != 0) {
        die "Error deploying foundation stack: $cdk_command\n$output\n";
    }
    print "Success\n";
}

sub bootstrap_cdk_environment() {
    chdir ($deploy_dir);
    my $cdk_command = "cdk bootstrap --profile $awsProfile";
    for my $context_argument (@main::context_variables) {
        $cdk_command .= " --context $context_argument";
    }

    my $output = `$cdk_command`;

    if ($? != 0) {
        print "Error running cdk deploy command: $cdk_command\n";
        print "$output\n";
        die;
    }
}

sub run_cdk_deploy {
    chdir ($deploy_dir);
    my ($tag) = @_;
    my $cdk_command = "cdk deploy --all --context service.dockerImageTag=$tag --profile $awsProfile  --require-approval never";
    for my $context_argument (@main::context_variables) {
        $cdk_command .= " --context $context_argument";
    }

    my $config = $cdkConfig;
    for my $property (keys %{$config}) {
        if (ref($config->{$property}) eq 'ARRAY') {
            $cdk_command .= " --context $property=";            
            $cdk_command .= join(',', @{$config->{$property}});            
        }
        else {
            $cdk_command .= " --context $property=$config->{$property}";
        }
    }

    #  Redirect standard error to standard output so it can be easily captured
    # $cdk_command .= " 2>&1";

    print "Deploying resources to AWS ... ";
    my $output = `$cdk_command`;

    if ($? != 0) {
        print "\n";
        if ($output =~ /Unable to fetch parameters \[(.+)\]/) {
            print "-" x 80, "\n";
            print "Missing parameter:  Add a value for $1 to the\nSSM Parameter Store for $accountId\n";
            print "-" x 80, "\n";
        }
        else {
            print "Error running cdk deploy command: $cdk_command\n";
            print "$output\n";            
        }
        die;
    }    
    print "Success\n";    
}

sub write_amplify_configuration() {
    print "Updating Amplify configuration\n";

    print "\tListing user pools for $awsProfile ... ";
    my $list_user_pools_command = "aws cognito-idp list-user-pools --profile $awsProfile --max-results 10";
    my $output = `$list_user_pools_command`;
    if ($? != 0) {
        die "Failed to execute $list_user_pools_command to list user pools";
    }
    print "Success\n";

    print "\tLocating application user pool ... ";
    my $user_pools = decode_json($output);
    
    # Process the JSON output to extract the desired user pool information
    my $user_pool_id = "";
    my $user_pool_name = "$applicationName-user-pool";

    foreach my $user_pool (@{$user_pools->{"UserPools"}}) {
        if ($user_pool->{Name} eq $user_pool_name) {
            $user_pool_id = $user_pool->{Id};
            last;
        }
    }
    if ($user_pool_id eq "") {
        die "Couldn't find user pool named $user_pool_name";
    }
    print " found $user_pool_id\n";

    unless ($user_pool_id) {
        die "Could not find a user pool with the name $applicationName";
    }

    print "\tGetting details about $user_pool_id ... ";
    my $describe_user_pool_cmd = "aws cognito-idp describe-user-pool --profile $awsProfile --user-pool-id $user_pool_id";

    $output = `$describe_user_pool_cmd`;
    die "\nFailed to execute $describe_user_pool_cmd" unless ($? == 0); 
    print " Success\n";

    #  There should only be one app client at least for now
    my $user_pool_details = decode_json($output)->{"UserPool"};  

    print "\tGetting app clients ... ";
    my $list_app_clients_cmd = "aws cognito-idp list-user-pool-clients --profile $awsProfile --user-pool-id $user_pool_id";
    $output = `$list_app_clients_cmd`;

    die "Failed to exeucte $list_app_clients_cmd to list app_clients" unless ($? == 0);

    my $app_clients = decode_json($output);
    my $clients = $app_clients->{"UserPoolClients"};
    my $number_of_clients = @{$clients};

    die "\nWrong number of user pool clients found: $number_of_clients" unless ($number_of_clients == 1);
    
    my $app_client = $clients->[0];
    my $app_client_id = $clients->[0]->{"ClientId"};

    print " found $app_client_id\n";

    my $describe_app_client_cmd = "aws cognito-idp describe-user-pool-client --profile $awsProfile --user-pool-id $user_pool_id --client-id $app_client_id";

    print "\tGetting details about app client $app_client_id ... ";
    $output = `$describe_app_client_cmd`;
    die "Failed to execute $describe_app_client_cmd" unless ($? == 0);

    print "Success\n";
    $app_client = decode_json($output);
    $app_client = $app_client->{"UserPoolClient"};

    my $password_policy = $user_pool_details->{"Policies"}->{"PasswordPolicy"};    
    my $password_protection_settings = {
        "passwordPolicyMinLength" => $password_policy->{"MinimumLength"}
    };
    my $password_policy_characters = [];
    if ($password_policy->{"RequireUppercase"}) {
        push @{$password_policy_characters}, "REQUIRES_UPPERCASE"
    }
    if ($password_policy->{"RequireLowercase"}) {
        push @{$password_policy_characters}, "REQUIRES_LOWERCASE"
    }

    if ($password_policy->{"RequireNumbers"}) {
        push @{$password_policy_characters}, "REQUIRES_NUMBERS"
    }

    if ($password_policy->{"RequireSymbols"}) {
        push @{$password_policy_characters}, "REQUIRES_SYMBOLS"
    }

    $password_protection_settings->{"passwordPolicyCharacters"} = $password_policy_characters;

    my $username_attributes = [];
    my @username_attributes = @{$user_pool_details->{"UsernameAttributes"}};
    for my $attribute (@username_attributes) {
        push @{$username_attributes}, uc($attribute);
    }

    my @social_providers = ();
    for my $provider (@{$app_client->{"SupportedIdentityProviders"}}) {
        push @social_providers, uc($provider) unless ($provider eq "COGNITO")
    };

    my $amplify_config = {
        "Version" => "1.0", 
        "auth" => {
            "plugins"=> {
                "awsCognitoAuthPlugin" => {
                    "Version" => "0.1.0",
                    "IdentityManager" => { "Default" => {} },
                    "CognitoUserPool" => {
                        "Default" => {
                            "PoolId" => "$user_pool_id",
                            "AppClientId" => "$app_client_id",
                            "Region" => $region
                        }
                    },
                    "Auth" => {
                        "Default" => {
                            "authenticationFlowType" => "USER_SRP_AUTH",
                            "socialProviders" => \@social_providers,
                            "mfaConfiguration" => $user_pool_details->{"MfaConfiguration"},
                            "mfaTypes" => [],
                            "passwordProtectionSettings" => $password_protection_settings,
                            "usernameAttributes" =>  $username_attributes
                        }
                    }
                }
            }
        }
       
    };


    my $google_auth_enabled = read_value_from_cdk_json("cognito.googleLogin.enabled");

    if ($google_auth_enabled) {
       
        $amplify_config->{"auth"}->{"plugins"}->{"awsCognitoAuthPlugin"}->{"Auth"}->{"Default"}->{"OAuth"} = {
            "WebDomain" => "$applicationName.auth.$region.amazoncognito.com",
            "AppClientId" => $app_client_id,
            "Scopes" => $app_client->{"AllowedOAuthScopes"},
            "SignOutRedirectURI" => join (",", @{$app_client->{"LogoutURLs"}}),
            "SignInRedirectURI" => join (",", @{$app_client->{"CallbackURLs"}})            
        }
    }

    #print to_json($amplify_config, {'pretty'=>1});

    # Write the Amplify configuration file    
    print "\tWriting configuration to $amplify_configuration_file ... ";
    open(my $fh, '>', $amplify_configuration_file) or die "Could not open file '$amplify_configuration_file' for writing ($!)";
    print $fh to_json($amplify_config, {'pretty'=>1});
    close($fh);
    print "Success\n";
    
}

sub create_dns_update_doc {
    my ($load_balancer_dns_name) = @_;
    my $input_file = catfile(
        $deploy_dir, "update_dns_loadbalancer_template.json"
    );
    
    open (my $fh, $input_file) or die "Failed to open $input_file to update DNS load balancer name";
    my @lines = <$fh>;
    my $output_doc = "";
    for my $line (@lines) {
        $line =~ s/DNS_RECORD/$load_balancer_dns_name/;
        $line =~ s/projectname/$awsProfile/;
        $output_doc .= $line;
    } 
    return $output_doc;
}

sub update_load_balancer_name {
    my $list_profiles_cmd = "aws configure list-profiles";
    my $profile_output = `$list_profiles_cmd`;
    my $dns_update_profile = "updatedns";

    chomp ($profile_output);

    my @profiles = split /\n/, $profile_output;
    my @found_profiles = grep /$dns_update_profile/, @profiles;
    if (@found_profiles == 0) {
        print STDERR "Did not find an AWS profile named $dns_update_profile\n";
        print STDERR "Create this profile using the information in "
    }

    my $cmd = "aws elbv2 describe-load-balancers --names staging-loadbalancer --profile $awsProfile";
    my $load_balancer_info =  `$cmd`;

    if ($? != 0) {
        die "Error retrieving load balancer information using command: $cmd";
    }

    if ($load_balancer_info =~ /DNSName": "(.*)"/) {
        my $load_balancer_dns_name = $1;
        my $hosted_zone_id = "Z0945425244GIHSGKLIEM";

        my ($fh, $filename) = tempfile();
        my $doc = create_dns_update_doc($load_balancer_dns_name);
        print $fh $doc;
        close($fh);

        my $update_dns_cmd = "aws route53 change-resource-record-sets --profile $dns_update_profile --hosted-zone-id $hosted_zone_id --change-batch file://$filename";

        print "Updating the DNS record for $awsProfile.hopesoftware.institute ... ";
        my $update_output = `$update_dns_cmd`;

        if ($? != 0) {
            die "\nError retrieving updating load balancer information using command: $update_dns_cmd\n$update_output\n";
        }

        print "Success\n";
    }
}

write_amplify_configuration();
exit 0;

compile_webapp() unless (!$compile_webapp);
compile_server() unless (!$compile_server);

log_into_ecr();

my $docker_image_tag = build_and_push_docker_image($build_docker_image)
  unless (!$build_docker_image);

#  $docker_image_tag will be 1 if this is the first build
delete_existing_docker_image($docker_image_tag-1)
    unless (!$build_docker_image || $docker_image_tag == 1);

run_cdk_deploy($docker_image_tag);

update_load_balancer_name()
    unless (!$update_load_balancer_dns);

write_amplify_configuration();