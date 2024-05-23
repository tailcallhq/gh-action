const core = require('@actions/core');

async function run() {
    try {
        const aws = core.getInput('aws');
        const fly = core.getInput('fly');
        const tailcallConfig = core.getInput('tailcall-config');

        // Parse the JSON inputs if they are passed as strings
        const awsConfig = aws ? JSON.parse(aws) : null;
        const flyConfig = fly ? JSON.parse(fly) : null;

        // Use the AWS and Fly.io configurations as needed
        if (awsConfig) {
            core.info(`Using AWS configuration: ${JSON.stringify(awsConfig)}`);
            // Your logic to use AWS credentials and configuration
        }

        if (flyConfig) {
            core.info(`Using Fly.io configuration: ${JSON.stringify(flyConfig)}`);
            // Your logic to use Fly.io credentials and configuration
        }

        core.info(`Using Tailcall config: ${tailcallConfig}`);
        // Your logic to use the Tailcall configuration

    } catch (error) {
        core.setFailed(`Action failed with error: ${error}`);
    }
}

run();