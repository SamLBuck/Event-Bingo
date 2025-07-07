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

my $dns_update_profile = "updatedns";

my $root_dir = dirname(abs_path($0));
my $server_dir = catfile($root_dir, "server");
my $client_dir = catfile($root_dir, "web");
my $webapp_dir = catfile($server_dir, "src", "main", "resources", "static", "app");
my $deploy_dir = catfile($root_dir, "infrastructure");
my $amplify_configuration_dir = catfile ("mobile", "assets");
my $amplify_configuration_file = catfile($amplify_configuration_dir, "amplifyconfiguration.json");

my $compile_webapp = -1;
my $compile_server = 1;
my $build_docker_image = 1;
my $update_load_balancer_dns = 1;

my $temporary_password = "";

my $mode_deploy = "deploy";
my $mode_destroy = "destroy";
my $mode_update_amplify_config = "update-amplify-config";
my $mode_create_users = "create-cognito-users";

my $mode = $mode_deploy;

my @mode_options = (
  $mode_deploy,
  $mode_destroy,
  $mode_update_amplify_config,
  $mode_create_users
);

my $alternate_cdk_json_path = "";
my $cdkConfig = "";

my $show_help = 0;
our @context_variables = ();

sub read_alternate_cdk_json_file($) {
    my ($path) = @_;

    my $json_text = read_file($path);
    my $json_output = decode_json($json_text);

    return $json_output;
}

GetOptions('webapp!' => \$compile_webapp, 'server!' => \$compile_server, 'mode=s' => \$mode,
    'update-dns!' => \$update_load_balancer_dns, 'cdk-config=s' => \$alternate_cdk_json_path,
    'build_docker_image!' => \$build_docker_image, 'context=s@' => \@context_variables,     
    'temporary-password=s' => \$temporary_password,
    'help' => \$show_help);

if ($show_help) {
    print "Usage: perl deploy.pl [--mode mode] [--no-webapp] [--no-server] [--no-build_docker_image] [--no-update-dns] [--cdk-config config.json] [--temporary-password password] [--help]\n\n";
    print "Options for --mode are ", join(",", @mode_options), "\n";
    print "Default mode is $mode_deploy\n";
    print "Both the management web application and the backend API server will be built by default\n";
    print "Use the --nowebapp and --no-server options to use an existing compiled version of those components\n";
    exit (0);
}

unless (grep { $_ eq $mode } @mode_options) {
    die "Invalid mode: $mode. Valid options are: " . join(", ", @mode_options) . "\n";
}

if ($alternate_cdk_json_path) {
    $cdkConfig = read_alternate_cdk_json_file($alternate_cdk_json_path);
}

sub is_true ($) {
    my ($value) = @_;
    return $value eq "1" || $value eq "true";
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
    my $json_text = read_file($cdk_json_path);
    my $context = decode_json($json_text)->{context};

    if (!exists $context->{$variableName}) {
        die "Could not find $variableName in $cdk_json_path";
    }
    else {
        my $value = $context->{$variableName};
        if ($value eq "default") {
            print STDERR "The value of the property $variableName in cdk.json is still set to \"default\"\n";
            print STDERR "You must change this to the appropriate value\n";
            exit(1);
        }
        return $value;
    }
}

sub check_if_profile_exists ($) {
    my ($desired_profile) = @_;
    my $cmd = "aws configure list-profiles";
    my $output = `$cmd`;
    
    unless ($? == 0) {
        die "Failed to list AWS profiles using cmd $cmd";
    }

    my @profiles = split /\n/, $output;
    my @matches = grep /$desired_profile/, @profiles;
    return @matches == 1;
}

sub verify_profiles {
    my $profile_to_use = read_value_from_cdk_json("awsProfile");
    unless (check_if_profile_exists($profile_to_use)) {
        my $error = "The AWS profile $profile_to_use does not exist\n";
        my $configFile = "cdk.json";        
        if ($cdkConfig && exists $cdkConfig->{"awsProfile"}) {
            $configFile = $alternate_cdk_json_path;
        }
        $error .= "Check the value for the property awsProfile specified in the file $configFile\n";
        
        die $error;
    }

    unless (check_if_profile_exists($dns_update_profile)) {
        my $error = "ERROR: The AWS profile $dns_update_profile does not exist.\n" .
                    "See the information at https://link.hope.edu/updatedns for details\n" .
                    "If you don't have access to this document, contact your instructor\n";
        die $error;                    
    }
}

if  ($compile_webapp == -1) {
    $compile_webapp = read_value_from_cdk_json("compile.webapp");
    $compile_webapp = is_true($compile_webapp);
}

my $accountId = read_value_from_cdk_json("accountId");
my $region = read_value_from_cdk_json("region");
my $awsProfile =  read_value_from_cdk_json("awsProfile");

my $applicationName = read_value_from_cdk_json("applicationName");
my $environmentName = read_value_from_cdk_json("environmentName");

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
    if ($config) {
        for my $property (keys %{$config}) {
            if (ref($config->{$property}) eq 'ARRAY') {
                $cdk_command .= " --context $property=";            
                $cdk_command .= join(',', @{$config->{$property}});            
            }
            else {
                $cdk_command .= " --context $property=$config->{$property}";
            }
        }
    }

    print "Deploying resources to AWS ... ";
    my $output = "";
    open (my $pipe, "$cdk_command |") or die "Cannot execute $cdk_command: $!";

    while (my $line = <$pipe>) {
        print $line;
        $output .= $line;
    }    

    close ($pipe);

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

sub run_cdk_destroy {    
    my $cdk_command = "cdk destroy --all --force --profile $awsProfile";


    my $listRepositoriesCmd = "aws ecr describe-repositories --profile $awsProfile --query repositories[*].repositoryName --output text";

    print "Checking for existing ECR repositories ... ";
    my $repositoriesOutput = `$listRepositoriesCmd`;
    
    if ($repositoriesOutput eq "") {
        print "none found\n"
    }
    elsif ($repositoriesOutput =~ /$applicationName/) {
        print "Removing any docker images still in application's repository ... ";
        my $list_images_cmd = "aws ecr describe-images --repository-name $applicationName --profile $awsProfile --query imageDetails[*].imageDigest --output text";

        my $imageDigests = `$list_images_cmd`;
        if ($? != 0) {
            die "Failed\nError listing images in ECR repository $awsProfile\nCommand used was\n$list_images_cmd\n";
        }

        if ($imageDigests ne "") {
            my @images = split /\s/, $imageDigests;
            @images = map {"imageDigest=$_"} @images;
            my $imageList = join " ", @images;

            my $deleteImagesCmd = "aws ecr batch-delete-image --repository-name $applicationName --profile $awsProfile --image-ids $imageList";

            my $output = `$deleteImagesCmd`;
            if ($? != 0) {
                die "Failed\nCommand used was\n$deleteImagesCmd\n";
            }
        }
        else {
            print "(none found) ";
        }
        print "Success\n";
    }

    chdir ($deploy_dir);    
    print "Destroying all resources  ... ";

    open (my $pipe, "$cdk_command |") or die "Cannot execute $cdk_command: $!";

    while (my $line = <$pipe>) {
        print $line;
    }    

    close ($pipe);

    #  Must check $? after close
    my $exit_status = $? >> 8;
    
    if ($exit_status == 0) {
        print "Success\n"
    }
    else {
        print "Failed\n";
        print "\tCommand: $cdk_command\n";        
        die "AWS resources not destroyed"; 
    }
}

sub cleanup_other_stacks() {        
    print "\tChecking Cloud Formation Stacks ... ";

    my $list_stacks_command = "aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile $awsProfile";
    my $list_stacks_output = `$list_stacks_command`;

    if ($? != 0) {
        die "Error executing $list_stacks_command: $list_stacks_output";
    }

    my @stacks = split /\s/, $list_stacks_output;
    if (@stacks > 0) {
        print "\t\tFound ", scalar @stacks, " stacks\n";
        for my $stack_name (@stacks) {
            my $delete_stack_cmd = "aws cloudformation delete-stack --stack-name $stack_name --region $region --profile $awsProfile";
            print "\t\tDeleting stack $stack_name ... ";
            my $delete_stack_output = `$delete_stack_cmd`;
            if ($? != 0) {
                die "Failed to delete stack $stack_name using command $delete_stack_cmd\n$delete_stack_output\n";
            }
            else {
                my $wait_for_completion_command = "aws cloudformation wait stack-delete-complete --stack-name $stack_name --region $region --profile $awsProfile";
                my $wait_for_completion_output = `$wait_for_completion_command`;
            }
            print "done\n";
        }
    }
    else {
        print "\t\tNone found\n";
    }
    print "\tSuccess\n";
}

sub delete_bootstrap_s3_bucket() {
    my $bucket_name = "cdk-hnb659fds-assets-$accountId-$region";
    print "\tCleaning up S3 resource $bucket_name ... ";

    # Empty the bucket first
    my $empty_bucket_cmd = "aws s3 rm s3://$bucket_name --recursive --profile $awsProfile";
    my $empty_bucket_output = `$empty_bucket_cmd`;
    if ($? != 0) {
        die "Failed to empty S3 bucket using command: $empty_bucket_cmd\n$empty_bucket_output\n";
    }

    # Then delete it
    my $delete_bucket_cmd = "aws s3api delete-bucket --bucket $bucket_name --profile $awsProfile";
    my $delete_bucket_output = `$delete_bucket_cmd`;
    if ($? != 0) {
        die "Failed to delete S3 bucket using command: $delete_bucket_cmd\n$delete_bucket_output\n";
    }
    print "Success\n";
}

sub get_user_pool_id() {
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

    return $user_pool_id;
}

sub get_temporary_cognito_password() {
    if ($temporary_password ne "") {
        return $temporary_password;
    }
    else {
        require Term::ReadKey;
        print "\tEnter temporary password for new Cognito users: ";
        Term::ReadKey::ReadMode('noecho');
        chomp($temporary_password = <STDIN>);
        Term::ReadKey::ReadMode('restore');
        print "\n";
        return $temporary_password;
    }
}

sub get_cognito_groups_for_user ($$) {
    my ($email_address, $user_pool_id) = @_;
    my $cmd = 
        "aws cognito-idp admin-list-groups-for-user " .
        "--username $email_address " .
        "--user-pool-id $user_pool_id " .
        '--query "Groups[*].GroupName" ' .
        "--output text " .
        "--region $region " .
        "--profile $awsProfile";

    my $output = `$cmd`;
    unless ($? == 0) {
        die "Failed to execute $cmd to list user's groups";
    }

    return split /\s/, $output;
}

sub remove_user_from_group($$$) {
    my ($email_address, $group_name, $user_pool_id) = @_;

    my $cmd = 
        "aws cognito-idp admin-remove-user-from-group " .
        "--user-pool-id $user_pool_id " .
        "--username $email_address " .
        "--group-name $group_name " .
        "--region $region " .
        "--profile $awsProfile";

    my $output = `$cmd`;

    unless ($? == 0) {
        die "Failed to delete user $email_address from group $group_name\nOutput was $output\nCommand used was $cmd\n";
    }    
}

sub create_cognito_users() {
    my $user_pool_id = get_user_pool_id();
    my @existing_users = ();

    print "Checking for cognito users to create: ";
    my $users = read_value_from_cdk_json("cognito.users");
    
    if (@$users == 0) {
        print "No users exists in cdk.json\n";
        return;
    }
    else {
        print scalar @$users, " user(s) exist in cdk.json\n";
        my $list_users_cmd = 
            "aws cognito-idp list-users " .
            "--user-pool-id $user_pool_id " .
            "--region $region " .
            "--profile $awsProfile " . 
            "--query \"Users[*].Attributes[?Name=='email'].Value\" " .
            "--output text ";
        @existing_users = split /\n/, `$list_users_cmd`;           
    }

    my $temp_password = get_temporary_cognito_password();

    for my $userhash (@$users) {        
        my $given_name = $userhash->{"given_name"};
        my $family_name = $userhash->{"family_name"};
        my $email_address = $userhash->{"email_address"};

        my @already_exists = grep /$email_address/, @existing_users;
        if (@already_exists == 0) {
            print "\tCreating cognito account for $email_address ... ";

            my $create_user_command = 
                "aws cognito-idp admin-create-user " .
                "--user-pool-id $user_pool_id " .
                "--username $email_address " .
                "--temporary-password $temp_password " .
                "--user-attributes " .
                "Name=email,Value=$email_address " .
                "Name=given_name,Value=$given_name " .
                "Name=family_name,Value=$family_name " .
                "Name=email_verified,Value=true " .
                "--message-action SUPPRESS " .
                "--profile $awsProfile " .
                "--region $region";

            my $output = `$create_user_command`;

            unless ($? == 0) {
                print STDERR "Failed to create cognito user for $email_address\n";
                print STDERR "$output\n";
                exit(1);
            }

            print " Success\n";
        }
        else {
            print "\t$email_address:  account already exists\n";
        }

        if (exists $userhash->{"groups"}) {
            my @groups = @{$userhash->{"groups"}};
            my @current_groups = get_cognito_groups_for_user($email_address, $user_pool_id);            

            my @new_groups = grep { my $g = $_; not grep { $_ eq $g } @current_groups } @groups;

            for my $group (@new_groups) {
                print "\t\tAdding $email_address to group $group ...";
                my $add_to_group_command = 
                    "aws cognito-idp admin-add-user-to-group " .
                    "--user-pool-id $user_pool_id " .
                    "--username $email_address " .
                    "--group-name $group " .
                    "--region $region " .
                    "--profile $awsProfile";
                
                my $output = `$add_to_group_command`;

                print " Success\n";
            }

            my @deleted_groups = grep { my $g = $_; not grep { $_ eq $g } @groups } @current_groups;

            for my $group (@deleted_groups) {
                print "\t\tDeleting $email_address from group $group ... ";
                remove_user_from_group ($email_address, $group, $user_pool_id);
                print "Success\n";
            }
        }                
    }
}

sub read_cognito_information() {
    print "\tListing user pools for $awsProfile ... ";

    my $user_pool_id = get_user_pool_id();

    print "\tGetting details about $user_pool_id ... ";
    my $describe_user_pool_cmd = "aws cognito-idp describe-user-pool --profile $awsProfile --user-pool-id $user_pool_id";

    my $output = `$describe_user_pool_cmd`;
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

    my $auth = {        
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
                        "usernameAttributes" =>  $username_attributes,
                        "signupAttributes" => []
                    }
                }
            }
        }           
    };

    my $google_auth_enabled = read_value_from_cdk_json("cognito.googleLogin.enabled");

    if ($google_auth_enabled) {       
        $auth->{"plugins"}->{"awsCognitoAuthPlugin"}->{"Auth"}->{"Default"}->{"OAuth"} = {
            "WebDomain" => "$applicationName.auth.$region.amazoncognito.com",
            "AppClientId" => $app_client_id,
            "Scopes" => $app_client->{"AllowedOAuthScopes"},
            "SignOutRedirectURI" => join (",", @{$app_client->{"LogoutURLs"}}),
            "SignInRedirectURI" => join (",", @{$app_client->{"CallbackURLs"}})            
        }
    }
    return $auth;
}

sub read_pinpoint_information($) {    
    my ($cognitoAuthPlugin) = @_;

    my $project_name = "$environmentName-$applicationName-pinpoint-app";

    my $list_pinpoint_apps_cmd = "aws pinpoint get-apps --profile $awsProfile";

    print "Listing pinpoint applications for $awsProfile ... ";
    my $output = `$list_pinpoint_apps_cmd`;
    die "Failed to list pinpoint apps using $list_pinpoint_apps_cmd" unless ($? == 0);
    print" Success\n";

    my $json_output = decode_json($output);
    my $items = $json_output->{"ApplicationsResponse"}->{"Item"};
    my $app_id = "";

    print "\tLocation application pinpoint project ... ";
    for my $item (@{$items}) {
        if ($item->{"Name"} eq $project_name) {
            $app_id = $item->{"Id"};
        }
    }
    die "Cannot find pinpoint project with name $project_name in account $awsProfile" unless($app_id);
    print "Success\n";

    print "\tLooking for Cognito Identity Pool ... ";

    my $cognito_identity_pool_cmd = 
        "aws cognito-identity list-identity-pools --profile $awsProfile --max-results 10";

    my $identity_pools_output = `$cognito_identity_pool_cmd`;
    if ($? != 0) {
        die "Failed to execute $cognito_identity_pool_cmd to list identity pools";
    }

    my $identity_pools = decode_json($identity_pools_output);
    my $identity_pool_id = "";

    my $identity_pool_name = "$environmentName-pinpoint-identity-pool";

    foreach my $identity_pool (@{$identity_pools->{"IdentityPools"}}) {
        if ($identity_pool->{"IdentityPoolName"} eq $identity_pool_name) {
            $identity_pool_id = $identity_pool->{"IdentityPoolId"};
            last;
        }
    }

    if ($identity_pool_id eq "") {
        die "Couldn't find identity pool named $identity_pool_name";
    }

    print " found $identity_pool_id\n";

    my $notifications = {
        "plugins" => {
            "awsPinpointPushNotificationsPlugin" => {
                "appId" => "$app_id",
                "region" => "$region"
            }
        }
    };

    $cognitoAuthPlugin->{"CredentialsProvider"} = {
            "CognitoIdentity" => {
                "Default" => {
                    "PoolId" => "$identity_pool_id",
                    "Region" => "$region"
                }
            }
    };

    return ($app_id, $notifications);
}

sub update_fcm_config($) {
    my ($project_id) = @_;

    my $parameterName = "/pinpoint/google/ApiKey";

    my $configuration = `aws ssm get-parameter --name $parameterName --with-decryption --query "Parameter.Value" --output text --region $region --profile $awsProfile`;
    unless ($? == 0) {
        die "Failed to read parameter value with key $parameterName.  Be sure this parameter has been created in the AWS parameter store for the account $awsProfile" 
    }

    chomp($configuration);

    my $cmdInput = {
        "DefaultAuthenticationMethod" => "TOKEN",
        "Enabled" => JSON::true
    };

    $cmdInput->{"ServiceJson"} = $configuration;

    use File::Temp 'tempfile';

    my ($temp_fh, $temp_filename) = tempfile(SUFFIX => '.json');
    print $temp_fh encode_json($cmdInput);
    close $temp_fh;

    my $cmd = "aws pinpoint update-gcm-channel --application-id $project_id --gcm-channel-request file://$temp_filename --profile $awsProfile --region $region";
    
    my $output = `$cmd`;

    unless ($? == 0) {
        die "Failed to update the gcm channel for pinpoint project.\nCommand was $cmd\nOutput was $output";
    }

    print "Success\n";
}

sub write_amplify_configuration() {
    print "Updating Amplify configuration\n";

    my $amplify_config = {
        "Version" => "1.0"
    };

    if (
        is_true(read_value_from_cdk_json("cognito.enabled")) || 
        is_true(read_value_from_cdk("notifications_enabled"))
    ) {
        $amplify_config->{"auth"} = read_cognito_information();
    }

    if (is_true(read_value_from_cdk_json("notifications.enabled"))) {
        my $app_id = "";

        ($app_id, $amplify_config->{"notifications"}) = read_pinpoint_information($amplify_config->{"auth"}->{"plugins"}->{"awsCognitoAuthPlugin"});    

        print "\tUpdating FCM information for pinpoint application $app_id ... ";
        update_fcm_config($app_id);
    }
    
    my $configuration = {};

    if (-e $amplify_configuration_file) {
        $configuration = decode_json(read_file($amplify_configuration_file));
    }

    $configuration->{read_value_from_cdk_json("environmentName")} = $amplify_config;

    # Write the Amplify configuration file    
    print "\tWriting configuration to $amplify_configuration_file ... ";
    chdir ($root_dir);

    open(my $fh, '>', $amplify_configuration_file) or die "Could not open file '$amplify_configuration_file' for writing ($!)";
    print $fh to_json($configuration, {'pretty'=>1});
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

sub copy_website_to_server_static() {
    my $website_source = catfile ($root_dir, "website");
    unless (-e $website_source) {
        return;
    }

    my $target_dir = catfile ($server_dir, "src", "main", "resources", "static");
    use File::Path qw(make_path);

    unless (-d $target_dir) {
        make_path($target_dir) or die "Failed to create target directory $target_dir: $!";
    }

    use File::Copy::Recursive qw(dircopy);

    dircopy($website_source, $target_dir) or die "Failed to copy website files from $website_source to $target_dir: $!";
}

unless (-e $amplify_configuration_dir) {
    mkdir ($amplify_configuration_dir) or die "Failed to create amplify configuration directory $amplify_configuration_dir";
}

verify_profiles();

if ($mode eq $mode_update_amplify_config) {
    write_amplify_configuration();
    exit(0);    
}

if ($mode eq $mode_create_users) {
    create_cognito_users();
    exit(0);
}

if ($mode eq $mode_destroy) {
    print "Are you sure you want to delete the AWS resources for the account $awsProfile? (Y/n)";
    chomp (my $confirm = <>);
    if ($confirm =~ /y(es)?/i) {
        run_cdk_destroy();

        print "Looking for other AWS resources to clean up ...\n";
        cleanup_other_stacks();
        delete_bootstrap_s3_bucket();
    }

    print "All AWS resources deleted\n";
    
    exit(0);
}

compile_webapp() unless (!$compile_webapp);
compile_server() unless (!$compile_server);

log_into_ecr();

copy_website_to_server_static();

my $docker_image_tag = build_and_push_docker_image($build_docker_image)
  unless (!$build_docker_image);

run_cdk_deploy($docker_image_tag);

#  Can delete last docker image as long as the deployment has completed
#  successfully
#  $docker_image_tag will be 1 if this is the first build
delete_existing_docker_image($docker_image_tag-1)
    unless (!$build_docker_image || $docker_image_tag == 1);

update_load_balancer_name()
    unless (!$update_load_balancer_dns);

create_cognito_users();

write_amplify_configuration();