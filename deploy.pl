use strict;
use warnings;

use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use File::Spec::Functions 'catfile';
use File::Copy;
use File::Temp qw/ tempfile tempdir /;

use Getopt::Long;

my $root_dir = dirname(abs_path($0));
my $server_dir = catfile($root_dir, "server");
my $client_dir = catfile($root_dir, "web");
my $webapp_dir = catfile($server_dir, "src", "main", "resources", "static", "app");
my $deploy_dir = catfile($root_dir, "infrastructure");

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

    `mvn package -DskipTests=true`;
    die ("Failed to compile server") unless $? == 0;

    print "Success\n";
}
sub read_value_from_cdk_json () {
    my ($variableName) = @_;
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

    return $1;
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

sub build_and_push_docker_image {
    my ($build_docker_image) = @_;
    my $list_images_cmd = "docker image ls";
    my $list_images_output = `$list_images_cmd`;
    if ($? != 0) {
        die "Failed executing $list_images_cmd to obtain list of docker images\nVerify Docker is running\n";
    }
    
    my @output = split /\n/, $list_images_output;
    my @app_images = grep /.*\/$applicationName/, @output;
    my $tag = 1;
    my @versions = ();
    if (@app_images != -1) {
        for my $line (@app_images) {
            #  Just in case there's an issue where the tag isn't set to a number
            if ($line =~ /$applicationName\s+(\d+)\s+/) {
                push @versions, $1;
            }
            
        }
        my @sorted_versions = sort {$a <=> $b} @versions;
        $tag = $sorted_versions[@sorted_versions-1] + 1;
    }
    
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

    print "Building foundation stack ... ";
    `$cdk_command`;

    if ($? != 0) {
        die "Error deploying foundation stack: $cdk_command";
    }
    print "Success\n";
}

sub run_cdk_deploy {
    chdir ($deploy_dir);
    my ($tag) = @_;
    my $cdk_command = "cdk deploy --all --context dockerImageTag=$tag --profile $awsProfile  --require-approval never";
    `$cdk_command`;

    if ($? != 0) {
        die "Error running cdk deploy command: $cdk_command";
    }
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
        $output_doc .= $line;
    } 
    return $output_doc;
}

sub update_load_balancer_name {
    my $cmd = "aws elbv2 describe-load-balancers --names staging-loadbalancer --profile parkhope";
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

        my $update_dns_cmd = "aws route53 change-resource-record-sets --profile computerscience --hosted-zone-id $hosted_zone_id --change-batch file://$filename";

        print "Updating the DNS record for parkhope.hopesoftware.institute ... ";
        my $update_output = `$update_dns_cmd`;

        if ($? != 0) {
            die "\nError retrieving updating load balancer information using command: $update_dns_cmd\n$update_output\n";
        }

        print "Success\n";
    }
}

my $compile_webapp = 1;
my $compile_server = 1;
my $build_docker_image = 1;
my $show_help = 0;

GetOptions('webapp!' => \$compile_webapp, 'server!' => \$compile_server, 'build_docker_image!' => \$build_docker_image, 'help' => \$show_help);

if ($show_help) {
    print "Usage: perl deploy.pl [--no-webapp] [--no-server] [--no-build_docker_image] [--help]\n\n";
    print "Both the management web application and the backend API server will be built by default\n";
    print "Use the --nowebapp and --no-server options to use an existing compiled version of those components\n";
    exit (0);
}


compile_webapp() unless (!$compile_webapp);
compile_server() unless (!$compile_server);

build_foundation_stack();

log_into_ecr();
my $docker_image_tag = build_and_push_docker_image($build_docker_image)
  unless (!$build_docker_image);

# run_cdk_deploy($docker_image_tag);

# update_load_balancer_name();

