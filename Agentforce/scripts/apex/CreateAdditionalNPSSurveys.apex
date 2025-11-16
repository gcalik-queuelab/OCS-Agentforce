/**
 * Apex Anonymous Script to Create 2 Additional NPS Surveys
 *
 * This script creates:
 * - 2 NPS Surveys for existing "Grzegorz Calik Test Account"
 * - Each with 8 NPS Responses
 * - One with Promoter score (9), one with Passive score (7)
 *
 * To execute:
 * sf apex run -f scripts/apex/CreateAdditionalNPSSurveys.apex
 */

try {
    System.debug('=== Creating 2 Additional NPS Surveys ===');

    // STEP 1: Query for existing Account
    System.debug('Step 1: Querying for existing account...');
    List<Account> accounts = [
        SELECT Id, Name
        FROM Account
        WHERE Name = 'Grzegorz Calik Test Account'
        LIMIT 1
    ];

    if (accounts.isEmpty()) {
        System.debug('❌ ERROR: Account "Grzegorz Calik Test Account" not found. Please run CreateNPSSampleData.apex first.');
        return;
    }

    Account testAccount = accounts[0];
    System.debug('✓ Found account: ' + testAccount.Name + ' (ID: ' + testAccount.Id + ')');

    // STEP 2: Query for existing Contact
    System.debug('Step 2: Querying for existing contact...');
    List<Contact> contacts = [
        SELECT Id, FirstName, LastName
        FROM Contact
        WHERE AccountId = :testAccount.Id
        LIMIT 1
    ];

    if (contacts.isEmpty()) {
        System.debug('❌ ERROR: No contact found for this account.');
        return;
    }

    Contact testContact = contacts[0];
    System.debug('✓ Found contact: ' + testContact.FirstName + ' ' + testContact.LastName + ' (ID: ' + testContact.Id + ')');

    // STEP 3: Query for Grzegorz Calik User
    System.debug('Step 3: Querying for user Grzegorz Calik...');
    List<User> users = [
        SELECT Id, Name
        FROM User
        WHERE Name LIKE '%Grzegorz%Calik%'
        AND IsActive = true
        LIMIT 1
    ];

    if (users.isEmpty()) {
        System.debug('❌ ERROR: User "Grzegorz Calik" not found.');
        return;
    }

    User grzegorzUser = users[0];
    System.debug('✓ Found user: ' + grzegorzUser.Name + ' (ID: ' + grzegorzUser.Id + ')');

    // STEP 4: Get Account Record Type for NPS
    System.debug('Step 4: Getting NPS Account Record Type...');
    Id accountRecordTypeId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
        .get('Account').getRecordTypeId();
    System.debug('✓ Account Record Type ID: ' + accountRecordTypeId);

    // STEP 5: Create 2 NPS Surveys
    System.debug('Step 5: Creating 2 NPS Surveys...');
    List<NPS__c> npsSurveys = new List<NPS__c>();

    // Survey #1 - Promoter (Score 9)
    npsSurveys.add(new NPS__c(
        RecordTypeId = accountRecordTypeId,
        Account__c = testAccount.Id,
        Visiting_Contact__c = testContact.Id,
        NPS_Surveyor__c = grzegorzUser.Id,
        Status__c = 'Appointment Required',
        Due_Date__c = Date.today().addDays(14),
        OwnerId = UserInfo.getUserId()
    ));

    // Survey #2 - Passive (Score 7)
    npsSurveys.add(new NPS__c(
        RecordTypeId = accountRecordTypeId,
        Account__c = testAccount.Id,
        Visiting_Contact__c = testContact.Id,
        NPS_Surveyor__c = grzegorzUser.Id,
        Status__c = 'Appointment Required',
        Due_Date__c = Date.today().addDays(21),
        OwnerId = UserInfo.getUserId()
    ));

    insert npsSurveys;
    System.debug('✓ Created ' + npsSurveys.size() + ' NPS Surveys');
    System.debug('  Survey #1 ID: ' + npsSurveys[0].Id);
    System.debug('  Survey #2 ID: ' + npsSurveys[1].Id);

    // STEP 6: Create Responses for Survey #1 (Promoter - Score 9)
    System.debug('Step 6: Creating responses for Survey #1 (Promoter)...');
    List<NPS_Response__c> survey1Responses = new List<NPS_Response__c>();

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q10 - Would you recommend us?',
        Question__c = 'Would you recommend us?',
        Score__c = 9,
        Answer__c = 'Yes, highly recommend! Outstanding service and support.',
        Suggestion_for_improvement__c = 'Keep up the excellent work!'
    ));

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q1 - Contractual Delivery?',
        Question__c = 'Contractual Delivery?',
        Score__c = 9,
        Answer__c = 'Excellent delivery, always on time.',
        Suggestion_for_improvement__c = null
    ));

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q2 - How open & honest is our relationship?',
        Question__c = 'How open & honest is our relationship?',
        Score__c = 10,
        Answer__c = 'Completely transparent and trustworthy.',
        Suggestion_for_improvement__c = null
    ));

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q3 - Do we provide accurate information?',
        Question__c = 'Do we provide accurate information?',
        Score__c = 9,
        Answer__c = 'Very accurate and reliable.',
        Suggestion_for_improvement__c = null
    ));

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q4 - How innovative and creative are we?',
        Question__c = 'How innovative and creative are we?',
        Score__c = 8,
        Answer__c = 'Great innovative solutions.',
        Suggestion_for_improvement__c = null
    ));

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q5 - Do we support your business needs?',
        Question__c = 'Do we support your business needs?',
        Score__c = 10,
        Answer__c = 'Perfect alignment with our business goals.',
        Suggestion_for_improvement__c = null
    ));

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q6 - Are we improving?',
        Question__c = 'Are we improving?',
        Score__c = 9,
        Answer__c = 'Significant improvements noticed.',
        Suggestion_for_improvement__c = null
    ));

    survey1Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[0].Id,
        Name = 'Q7 - Further Comments',
        Question__c = 'Further Comments/Easier to work with?',
        Score__c = null,
        Answer__c = 'Fantastic partnership! The team consistently exceeds expectations and delivers exceptional value.',
        Suggestion_for_improvement__c = null
    ));

    insert survey1Responses;
    System.debug('✓ Created ' + survey1Responses.size() + ' responses for Survey #1');

    // STEP 7: Create Responses for Survey #2 (Passive - Score 7)
    System.debug('Step 7: Creating responses for Survey #2 (Passive)...');
    List<NPS_Response__c> survey2Responses = new List<NPS_Response__c>();

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q10 - Would you recommend us?',
        Question__c = 'Would you recommend us?',
        Score__c = 7,
        Answer__c = 'Yes, good service overall but some areas need improvement.',
        Suggestion_for_improvement__c = 'Faster response times on urgent issues would be helpful.'
    ));

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q1 - Contractual Delivery?',
        Question__c = 'Contractual Delivery?',
        Score__c = 7,
        Answer__c = 'Generally good, occasional delays.',
        Suggestion_for_improvement__c = 'More proactive communication on timelines.'
    ));

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q2 - How open & honest is our relationship?',
        Question__c = 'How open & honest is our relationship?',
        Score__c = 8,
        Answer__c = 'Honest and open most of the time.',
        Suggestion_for_improvement__c = null
    ));

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q3 - Do we provide accurate information?',
        Question__c = 'Do we provide accurate information?',
        Score__c = 7,
        Answer__c = 'Mostly accurate with some minor discrepancies.',
        Suggestion_for_improvement__c = 'Double-check information before sharing.'
    ));

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q4 - How innovative and creative are we?',
        Question__c = 'How innovative and creative are we?',
        Score__c = 6,
        Answer__c = 'Some good ideas but could be more innovative.',
        Suggestion_for_improvement__c = 'Bring more creative solutions to the table.'
    ));

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q5 - Do we support your business needs?',
        Question__c = 'Do we support your business needs?',
        Score__c = 7,
        Answer__c = 'Good support but not always aligned with our priorities.',
        Suggestion_for_improvement__c = 'Better understanding of our business objectives.'
    ));

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q6 - Are we improving?',
        Question__c = 'Are we improving?',
        Score__c = 7,
        Answer__c = 'Some improvements but progress is slow.',
        Suggestion_for_improvement__c = 'Faster implementation of feedback.'
    ));

    survey2Responses.add(new NPS_Response__c(
        NPS__c = npsSurveys[1].Id,
        Name = 'Q7 - Further Comments',
        Question__c = 'Further Comments/Easier to work with?',
        Score__c = null,
        Answer__c = 'Overall satisfied with the partnership but there is room for improvement in several areas, particularly around responsiveness and innovation.',
        Suggestion_for_improvement__c = 'More regular check-ins and status updates would help.'
    ));

    insert survey2Responses;
    System.debug('✓ Created ' + survey2Responses.size() + ' responses for Survey #2');

    // STEP 8: Query back and display results
    List<NPS__c> updatedSurveys = [
        SELECT Id, Name, Status__c, Recommend_Us_Score__c, Survey_Category__c,
               Total_NPS_Score__c, Number_of_NPS_Responses__c
        FROM NPS__c
        WHERE Id IN :npsSurveys
        ORDER BY CreatedDate
    ];

    System.debug('\n=== SURVEY CREATION SUCCESSFUL ===');

    for (Integer i = 0; i < updatedSurveys.size(); i++) {
        NPS__c survey = updatedSurveys[i];
        System.debug('\n=== SURVEY #' + (i + 1) + ' DETAILS ===');
        System.debug('NPS Name: ' + survey.Name);
        System.debug('NPS ID: ' + survey.Id);
        System.debug('Status: ' + survey.Status__c);
        System.debug('Recommend Us Score: ' + survey.Recommend_Us_Score__c);
        System.debug('Survey Category: ' + survey.Survey_Category__c);
        System.debug('Total NPS Score: ' + survey.Total_NPS_Score__c);
        System.debug('Number of Responses: ' + survey.Number_of_NPS_Responses__c);
        System.debug('View URL: /lightning/r/NPS__c/' + survey.Id + '/view');
    }

    System.debug('\n✓✓✓ All 2 NPS Surveys created successfully! ✓✓✓');
    System.debug('Total surveys for account "Grzegorz Calik Test Account": 3');

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
    throw e;
}
