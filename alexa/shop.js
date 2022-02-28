const Alexa = require('ask-sdk-core');
const { BatchClient, SubmitJobCommand } = require("@aws-sdk/client-batch");

const LaunchRequestHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'LaunchRequest';
    },
    async handle(handlerInput) {
        const client = new BatchClient();

        const arnPrefix = `arn:aws:batch:${process.env.AWS_REGION}:${process.env.ACCOUNT_ID}`;
        const params = {
          jobName: 'grocery-shopping-bot-job',
          jobQueue: `${arnPrefix}:job-queue/${process.env.JOB_QUEUE_NAME}`,
          jobDefinition: `${arnPrefix}:job-definition/${process.env.JOB_DEFINITION_NAME}`
        };

        // Kick off AWS Batch job
        const command = new SubmitJobCommand(params);
        await client.send(command);

        const speakOutput = 'starting bot';
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};

exports.handler = Alexa.SkillBuilders.custom()
    .addRequestHandlers(LaunchRequestHandler)
    .lambda();
