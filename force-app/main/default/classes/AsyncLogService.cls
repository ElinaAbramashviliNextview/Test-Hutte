/**
 * Created by David Martinka on 05.10.2022.
 * Mooza Inspire s.r.o.
 */

public with sharing class AsyncLogService {
    public static String TYPE_ERROR = 'Error';
    public static String TYPE_INFO = 'Info';
    public static String TYPE_DEBUG = 'Debug';

    private static final Integer MAXIMAL_TEXT_LENGTH_LONG = 131072;
    private static final Integer MAXIMAL_TEXT_LENGTH_STANDARD = 255;

    public  List<Database.SaveResult> publishLogs(List<Log_Event__e> logEvents) {
        return EventBus.publish(logEvents);
    }

    public class LogBuilder {
        private String className;
        private String methodName;
        private String type;
        private String debugInfoLog;
        private String recordId;
        private String errorDescription;
        private String errorMessage;
        private String errorStackTrace;
        private String httpRequestBody;
        private String httpRequestEndpoint;
        private String httpResponseBody;
        private Integer httpResponseStatusCode;

        private Log_Event__e logEvent;

        public LogBuilder setMandatoryFields(String type, String className, String methodName) {
            this.type = type;
            this.className = className?.abbreviate(MAXIMAL_TEXT_LENGTH_STANDARD);
            this.methodName = methodName?.abbreviate(MAXIMAL_TEXT_LENGTH_STANDARD);
            return this;
        }

        public LogBuilder setRecordId(String recordId) {
            this.recordId = recordId;
            return this;
        }

        public LogBuilder setDebugInfoLog(String debugInfoLog) {
            this.debugInfoLog = debugInfoLog?.abbreviate(MAXIMAL_TEXT_LENGTH_LONG);
            return this;
        }

        public LogBuilder setErrorFields(String errorDescription, String errorMessage, String errorStackTrace) {
            this.errorDescription = errorDescription?.abbreviate(MAXIMAL_TEXT_LENGTH_LONG);
            this.errorMessage = errorMessage?.abbreviate(MAXIMAL_TEXT_LENGTH_LONG);
            this.errorStackTrace = errorStackTrace?.abbreviate(MAXIMAL_TEXT_LENGTH_LONG);
            return this;
        }

        public LogBuilder setHttpRequestFields(String httpRequestBody, String httpRequestEndpoint) {
            this.httpRequestBody = httpRequestBody?.abbreviate(MAXIMAL_TEXT_LENGTH_LONG);
            this.httpRequestEndpoint = httpRequestEndpoint?.abbreviate(MAXIMAL_TEXT_LENGTH_STANDARD);
            return this;
        }

        public LogBuilder setHttpResponseFields(String httpResponseBody, Integer httpResponseStatusCode) {
            this.httpResponseBody = httpResponseBody?.abbreviate(MAXIMAL_TEXT_LENGTH_LONG);
            this.httpResponseStatusCode = httpResponseStatusCode;
            return this;
        }

        public Log_Event__e getLogEvent() {
            this.create();
            return this.logEvent;
        }

        public void log() {
            this.create();
            EventBus.publish(this.logEvent);
        }

        private void create() {
            Log_Event__e logEvent = new Log_Event__e(
                    Type__c = this.type,
                    Class_Name__c = this.className,
                    Method_Name__c = this.methodName,
                    Debug_Info_Log__c = this.debugInfoLog,
                    RecordId__c = this.recordId,
                    Error_Description__c = this.errorDescription,
                    Error_Stack_Trace__c = this.errorStackTrace,
                    Error_Message__c = this.errorMessage,
                    HTTP_Request_Body__c = this.httpRequestBody,
                    HTTP_Request_Endpoint__c = this.httpRequestEndpoint,
                    HTTP_Response_Body__c = this.httpResponseBody,
                    HTTP_Response_Status_Code__c = this.httpResponseStatusCode
            );

            this.logEvent = logEvent;
        }
    }
}