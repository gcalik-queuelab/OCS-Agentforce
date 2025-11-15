/**
 * @Name         AF_NPSTriggerHandlerTest
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Test class for AF_NPSTrigger, AF_NPSTriggerHandler, AF_NPSAISummaryQueueable,
 *               and AF_NPSPromptBuilder. Validates AI summary generation workflow.
 */
@IsTest
private class AF_NPSTriggerHandlerTest {

    /**
     * Setup test data - creates Account, Contact, and NPS record type
     */
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account for NPS AI Summary'
        );
        insert testAccount;

        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }

    /**
     * Test: Single NPS survey closed triggers AI summary creation
     */
    @IsTest
    static void testSingleNPSClosure_CreatesAISummary() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        // Get Account Record Type
        Id accountRTId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
            .get('Account').getRecordTypeId();

        // Create NPS survey
        NPS__c nps = new NPS__c(
            RecordTypeId = accountRTId,
            Account__c = testAccount.Id,
            Visiting_Contact__c = testContact.Id,
            Status__c = 'Pending Results'
        );
        insert nps;

        // Create NPS responses
        List<NPS_Response__c> responses = new List<NPS_Response__c>{
            new NPS_Response__c(
                NPS__c = nps.Id,
                Name = 'Q10 - Would you recommend us?',
                Question__c = 'Would you recommend us?',
                Score__c = 9,
                Answer__c = 'Excellent service and support!',
                Suggestion_for_improvement__c = 'Keep up the great work!'
            ),
            new NPS_Response__c(
                NPS__c = nps.Id,
                Name = 'Q1 - Contractual Delivery?',
                Question__c = 'Contractual Delivery?',
                Score__c = 8,
                Answer__c = 'Good delivery overall.',
                Suggestion_for_improvement__c = 'Faster response times would help.'
            )
        };
        insert responses;

        // Test: Change status to Closed
        Test.startTest();
        nps.Status__c = 'Closed';
        nps.Reviewed__c = Date.today();
        update nps;

        // Manually execute the queueable in test context
        Set<Id> closedIds = new Set<Id>{nps.Id};
        Map<Id, List<NPS_Response__c>> responseMap = new Map<Id, List<NPS_Response__c>>();
        responseMap.put(nps.Id, responses);
        AF_NPSAISummaryQueueable queueable = new AF_NPSAISummaryQueueable(responseMap, closedIds);
        queueable.execute(null);

        Test.stopTest();

        // Verify: NPS_Survey_Summary__c was created
        List<NPS_Survey_Summary__c> summaries = [
            SELECT Id, NPS_Survey__c, Account__c, AI_Summary__c,
                   Created_By_Agentforce__c, Summary_Language__c,
                   NPS_Score__c, Sentiment_Analysis__c
            FROM NPS_Survey_Summary__c
            WHERE NPS_Survey__c = :nps.Id
        ];

        System.assertEquals(1, summaries.size(), 'Should create exactly one summary');
        NPS_Survey_Summary__c summary = summaries[0];
        System.assertEquals(nps.Id, summary.NPS_Survey__c, 'Summary should link to NPS');
        System.assertEquals(testAccount.Id, summary.Account__c, 'Summary should link to Account');
        System.assertEquals(true, summary.Created_By_Agentforce__c, 'Should be marked as created by Agentforce');
        System.assertEquals('English', summary.Summary_Language__c, 'Should be in English');
        System.assertNotEquals(null, summary.AI_Summary__c, 'AI Summary should be populated');
        System.assertEquals(9, summary.NPS_Score__c, 'NPS Score should match');
        System.assertEquals('Positive', summary.Sentiment_Analysis__c, 'Promoter should be Positive sentiment');
    }

    /**
     * Test: Status change from Closed to another status should not trigger
     */
    @IsTest
    static void testStatusChangeFromClosed_DoesNotTrigger() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id accountRTId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
            .get('Account').getRecordTypeId();

        // Create already-closed NPS
        NPS__c nps = new NPS__c(
            RecordTypeId = accountRTId,
            Account__c = testAccount.Id,
            Visiting_Contact__c = testContact.Id,
            Status__c = 'Closed',
            Reviewed__c = Date.today()
        );
        insert nps;

        Test.startTest();
        // Change to different status (should not trigger)
        nps.Status__c = 'Pending Results';
        update nps;
        Test.stopTest();

        // Verify: No summary created
        Integer summaryCount = [SELECT COUNT() FROM NPS_Survey_Summary__c WHERE NPS_Survey__c = :nps.Id];
        System.assertEquals(0, summaryCount, 'Should not create summary when status changes FROM Closed');
    }

    /**
     * Test: Bulk closure of multiple NPS surveys
     */
    @IsTest
    static void testBulkNPSClosure() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id accountRTId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
            .get('Account').getRecordTypeId();

        // Create 10 NPS surveys
        List<NPS__c> npsList = new List<NPS__c>();
        for (Integer i = 0; i < 10; i++) {
            npsList.add(new NPS__c(
                RecordTypeId = accountRTId,
                Account__c = testAccount.Id,
                Visiting_Contact__c = testContact.Id,
                Status__c = 'Pending Results'
            ));
        }
        insert npsList;

        // Create responses for each
        List<NPS_Response__c> allResponses = new List<NPS_Response__c>();
        for (NPS__c nps : npsList) {
            allResponses.add(new NPS_Response__c(
                NPS__c = nps.Id,
                Question__c = 'Would you recommend us?',
                Score__c = 8
            ));
        }
        insert allResponses;

        Test.startTest();
        // Bulk close all surveys
        for (NPS__c nps : npsList) {
            nps.Status__c = 'Closed';
            nps.Reviewed__c = Date.today();
        }
        update npsList;

        // Manually execute queueable with bulk data
        Set<Id> closedIds = new Map<Id, NPS__c>(npsList).keySet();
        Map<Id, List<NPS_Response__c>> responseMap = new Map<Id, List<NPS_Response__c>>();
        for (NPS_Response__c resp : allResponses) {
            if (!responseMap.containsKey(resp.NPS__c)) {
                responseMap.put(resp.NPS__c, new List<NPS_Response__c>());
            }
            responseMap.get(resp.NPS__c).add(resp);
        }
        AF_NPSAISummaryQueueable queueable = new AF_NPSAISummaryQueueable(responseMap, closedIds);
        queueable.execute(null);

        Test.stopTest();

        // Verify: Summaries created for all
        Integer summaryCount = [SELECT COUNT() FROM NPS_Survey_Summary__c WHERE NPS_Survey__c IN :npsList];
        System.assertEquals(10, summaryCount, 'Should create summaries for all 10 NPS surveys');
    }

    /**
     * Test: AF_NPSPromptBuilder.buildPromptData creates proper formatted prompt
     */
    @IsTest
    static void testPromptBuilder_BuildsValidPrompt() {
        // Get test data
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        Contact testContact = [SELECT Id, Name FROM Contact LIMIT 1];
        Id accountRTId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
            .get('Account').getRecordTypeId();

        // Create NPS with full data
        NPS__c nps = new NPS__c(
            RecordTypeId = accountRTId,
            Account__c = testAccount.Id,
            Visiting_Contact__c = testContact.Id,
            Status__c = 'Closed',
            Survey_Category__c = 'Promoter',
            Comments__c = 'Overall great experience',
            Visiting_Comments__c = 'Client was very engaged',
            Reviewed__c = Date.today()
        );
        insert nps;

        // Query back with relationships
        nps = [
            SELECT Id, Name, Status__c, Survey_Category__c,
                   Account__c, Account__r.Name,
                   NPS_Contact__c, Visiting_Contact__c, Visiting_Contact__r.Name,
                   Visit_Start__c, Recommend_Us_Score__c, Average_Score__c,
                   Total_NPS_Score__c, Number_of_NPS_Responses__c,
                   Comments__c, Visiting_Comments__c
            FROM NPS__c
            WHERE Id = :nps.Id
        ];

        List<NPS_Response__c> responses = new List<NPS_Response__c>{
            new NPS_Response__c(
                NPS__c = nps.Id,
                Question__c = 'Would you recommend us?',
                Score__c = 9,
                Answer__c = 'Absolutely!',
                Suggestion_for_improvement__c = 'None'
            )
        };
        insert responses;

        Test.startTest();
        String prompt = AF_NPSPromptBuilder.buildPromptData(nps, responses);
        Test.stopTest();

        // Verify prompt contains expected content
        System.assert(prompt.contains('NPS SURVEY DATA'), 'Prompt should have header');
        System.assert(prompt.contains(nps.Name), 'Prompt should include survey name');
        System.assert(prompt.contains(testAccount.Name), 'Prompt should include account name');
        System.assert(prompt.contains('Would you recommend us?'), 'Prompt should include question');
        System.assert(prompt.contains('Absolutely!'), 'Prompt should include answer');
        System.assert(prompt.contains('EXECUTIVE SUMMARY'), 'Prompt should include instructions');
        System.assert(prompt.contains('KEY STRENGTHS'), 'Prompt should include instructions');
        System.assert(prompt.contains('RECOMMENDED ACTIONS'), 'Prompt should include instructions');
    }

    /**
     * Test: hasRequiredData validates properly
     */
    @IsTest
    static void testPromptBuilder_ValidatesRequiredData() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id accountRTId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
            .get('Account').getRecordTypeId();

        // Test: NPS with no responses
        NPS__c nps = new NPS__c(
            RecordTypeId = accountRTId,
            Account__c = testAccount.Id,
            Visiting_Contact__c = testContact.Id,
            Status__c = 'Closed'
        );
        insert nps;

        Boolean hasData = AF_NPSPromptBuilder.hasRequiredData(nps, new List<NPS_Response__c>());
        System.assertEquals(false, hasData, 'Should return false when no responses');

        // Test: NPS with responses but not Closed
        nps.Status__c = 'Pending Results';
        update nps;
        List<NPS_Response__c> responses = new List<NPS_Response__c>{
            new NPS_Response__c(NPS__c = nps.Id, Question__c = 'Test', Score__c = 5)
        };
        insert responses;

        hasData = AF_NPSPromptBuilder.hasRequiredData(nps, responses);
        System.assertEquals(false, hasData, 'Should return false when not Closed');

        // Test: Valid data
        nps.Status__c = 'Closed';
        update nps;
        hasData = AF_NPSPromptBuilder.hasRequiredData(nps, responses);
        System.assertEquals(true, hasData, 'Should return true when valid');
    }

    /**
     * Test: Different NPS categories generate appropriate sentiments
     */
    @IsTest
    static void testSentimentMapping_ForDifferentCategories() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id accountRTId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
            .get('Account').getRecordTypeId();

        // Test Detractor (score 0-6)
        NPS__c detractor = new NPS__c(
            RecordTypeId = accountRTId,
            Account__c = testAccount.Id,
            Visiting_Contact__c = testContact.Id,
            Status__c = 'Pending Results',
            Survey_Category__c = 'Detractor'
        );
        insert detractor;

        NPS_Response__c response = new NPS_Response__c(
            NPS__c = detractor.Id,
            Question__c = 'Would you recommend us?',
            Score__c = 5
        );
        insert response;

        Test.startTest();
        detractor.Status__c = 'Closed';
        detractor.Reviewed__c = Date.today();
        update detractor;

        // Execute queueable
        Set<Id> ids = new Set<Id>{detractor.Id};
        Map<Id, List<NPS_Response__c>> responseMap = new Map<Id, List<NPS_Response__c>>();
        responseMap.put(detractor.Id, new List<NPS_Response__c>{response});
        AF_NPSAISummaryQueueable queueable = new AF_NPSAISummaryQueueable(responseMap, ids);
        queueable.execute(null);
        Test.stopTest();

        NPS_Survey_Summary__c summary = [
            SELECT Sentiment_Analysis__c, Follow_Up_Required__c
            FROM NPS_Survey_Summary__c
            WHERE NPS_Survey__c = :detractor.Id
        ];

        System.assertEquals('Negative', summary.Sentiment_Analysis__c, 'Detractor should be Negative');
        System.assertEquals(true, summary.Follow_Up_Required__c, 'Detractor should require follow-up');
    }
}
