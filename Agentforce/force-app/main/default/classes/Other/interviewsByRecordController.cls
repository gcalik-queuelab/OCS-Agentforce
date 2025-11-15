public class interviewsByRecordController {

        @AuraEnabled
        public static List<FlowRecordRelation> getInterviews(Id recordId) {
            return [SELECT ParentId, Parent.InterviewLabel, Parent.PauseLabel,Parent.CurrentElement, Parent.CreatedDate, Parent.Owner.Name
                    FROM FlowRecordRelation
                    WHERE RelatedRecordId = :recordId];
        }

        @AuraEnabled
        public static FlowInterview deleteInterview(Id interviewId) {
            FlowInterview interview;
            delete [SELECT Id FROM FlowInterview WHERE Id = :interviewId];
            return interview;
        }
    }