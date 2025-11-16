/**
 * Apex Anonymous Script to Create NPS Sample Data
 *
 * This script creates:
 * - 1 Account (Grzegorz Calik Test Account)
 * - 1 Contact (based on Grzegorz Calik user)
 * - 1 NPS Survey (Status: Appointment Required)
 * - 8 NPS Responses (including the special Q10 question)
 *
 * To execute:
 * 1. Open Developer Console or VS Code
 * 2. Execute Anonymous Apex with this file content
 * OR use CLI: sf apex run -f scripts/apex/CreateNPSSampleData.apex
 */

try {
    System.debug('=== Starting NPS Sample Data Creation ===');

    // STEP 1: Query for Grzegorz Calik User
    System.debug('Step 1: Querying for user Grzegorz Calik...');
    List<User> users = [
        SELECT Id, FirstName, LastName, Email, Name
        FROM User
        WHERE Name LIKE '%Grzegorz%Calik%'
        AND IsActive = true
        LIMIT 1
    ];

    if (users.isEmpty()) {
        System.debug('❌ ERROR: User "Grzegorz Calik" not found. Please check the username.');
        return;
    }

    User grzegorzUser = users[0];
    System.debug('✓ Found user: ' + grzegorzUser.Name + ' (ID: ' + grzegorzUser.Id + ')');

    // STEP 2: Create Account
    System.debug('Step 2: Creating Account...');
    Account testAccount = new Account(
        Name = 'Grzegorz Calik Test Account'
    );
    insert testAccount;
    System.debug('✓ Account created: ' + testAccount.Name + ' (ID: ' + testAccount.Id + ')');

    // STEP 3: Create Contact
    System.debug('Step 3: Creating Contact...');
    Contact testContact = new Contact(
        FirstName = grzegorzUser.FirstName,
        LastName = grzegorzUser.LastName,
        Email = grzegorzUser.Email,
        AccountId = testAccount.Id,
        Title = 'Test Contact for NPS Survey'
    );
    insert testContact;
    System.debug('✓ Contact created: ' + testContact.FirstName + ' ' + testContact.LastName + ' (ID: ' + testContact.Id + ')');

    // STEP 4: Get Account Record Type for NPS
    System.debug('Step 4: Getting NPS Account Record Type...');
    Id accountRecordTypeId = Schema.SObjectType.NPS__c.getRecordTypeInfosByDeveloperName()
        .get('Account').getRecordTypeId();
    System.debug('✓ Account Record Type ID: ' + accountRecordTypeId);

    // STEP 5: Create NPS Survey
    System.debug('Step 5: Creating NPS Survey...');
    NPS__c npsSurvey = new NPS__c(
        RecordTypeId = accountRecordTypeId,
        Account__c = testAccount.Id,
        Visiting_Contact__c = testContact.Id,
        NPS_Surveyor__c = grzegorzUser.Id,
        Status__c = 'Appointment Required', // Initial status
        Due_Date__c = Date.today().addDays(7),
        OwnerId = UserInfo.getUserId()
        // Note: Owner-related fields will be auto-populated by Before-Save Flow
    );
    insert npsSurvey;
    System.debug('✓ NPS Survey created with Status: Appointment Required (ID: ' + npsSurvey.Id + ')');

    // STEP 6: Create NPS Responses
    System.debug('Step 6: Creating NPS Responses...');
    List<NPS_Response__c> responses = new List<NPS_Response__c>();

    // Q10 - "Would you recommend us?" (SPECIAL - triggers flow to update parent NPS)
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q10 - Would you recommend us?',
        Question__c = 'Would you recommend us?',
        Score__c = 9, // Score 9-10 = Promoter
        Answer__c = 'Yes, absolutely! Excellent service and great team. Very professional and always available.',
        Suggestion_for_improvement__c = 'Continue the great work!'
    ));

    // Q1 - Contractual Delivery
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q1 - Contractual Delivery?',
        Question__c = 'Contractual Delivery?',
        Score__c = 8,
        Answer__c = 'Good delivery overall, met most deadlines.',
        Suggestion_for_improvement__c = 'Slightly faster response time on urgent requests would be helpful.'
    ));

    // Q2 - How open & honest is our relationship?
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q2 - How open & honest is our relationship?',
        Question__c = 'How open & honest is our relationship?',
        Score__c = 9,
        Answer__c = 'Very transparent communication, always keep us informed.',
        Suggestion_for_improvement__c = null
    ));

    // Q3 - Do we provide accurate information?
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q3 - Do we provide accurate information?',
        Question__c = 'Do we provide accurate information?',
        Score__c = 10,
        Answer__c = 'Perfect accuracy, very reliable information.',
        Suggestion_for_improvement__c = null
    ));

    // Q4 - How innovative and creative are we?
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q4 - How innovative and creative are we?',
        Question__c = 'How innovative and creative are we?',
        Score__c = 7,
        Answer__c = 'Good ideas, room for more innovation.',
        Suggestion_for_improvement__c = 'Would love to see more cutting-edge solutions proposed.'
    ));

    // Q5 - Do we support your business needs?
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q5 - Do we support your business needs?',
        Question__c = 'Do we support your business needs?',
        Score__c = 9,
        Answer__c = 'Excellent support, very responsive to our business requirements.',
        Suggestion_for_improvement__c = null
    ));

    // Q6 - Are we improving?
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q6 - Are we improving?',
        Question__c = 'Are we improving?',
        Score__c = 8,
        Answer__c = 'Yes, noticeable improvements over the past year.',
        Suggestion_for_improvement__c = null
    ));

    // Q7 - Further Comments/Easier to work with?
    responses.add(new NPS_Response__c(
        NPS__c = npsSurvey.Id,
        Name = 'Q7 - Further Comments',
        Question__c = 'Further Comments/Easier to work with?',
        Score__c = null, // Text-only response
        Answer__c = 'Overall very satisfied with the partnership. The team is professional, responsive, and always willing to go the extra mile. Looking forward to continuing our collaboration.',
        Suggestion_for_improvement__c = 'More regular check-ins would be appreciated.'
    ));

    insert responses;
    System.debug('✓ Created ' + responses.size() + ' NPS Responses');

    // STEP 7: Query back and display results
    System.debug('\n=== DATA CREATION SUCCESSFUL ===');
    System.debug('Account ID: ' + testAccount.Id);
    System.debug('Contact ID: ' + testContact.Id);
    System.debug('NPS Survey ID: ' + npsSurvey.Id);
    System.debug('Number of Responses: ' + responses.size());

    // Query the NPS record to see if flows updated it
    NPS__c updatedNPS = [
        SELECT Id, Name, Status__c, Recommend_Us_Score__c, Survey_Category__c,
               Total_NPS_Score__c, Number_of_NPS_Responses__c
        FROM NPS__c
        WHERE Id = :npsSurvey.Id
        LIMIT 1
    ];

    System.debug('\n=== NPS SURVEY DETAILS ===');
    System.debug('NPS Name: ' + updatedNPS.Name);
    System.debug('Status: ' + updatedNPS.Status__c);
    System.debug('Recommend Us Score: ' + updatedNPS.Recommend_Us_Score__c);
    System.debug('Survey Category: ' + updatedNPS.Survey_Category__c);
    System.debug('Total NPS Score: ' + updatedNPS.Total_NPS_Score__c);
    System.debug('Number of Responses: ' + updatedNPS.Number_of_NPS_Responses__c);

    System.debug('\n✓✓✓ All sample data created successfully! ✓✓✓');
    System.debug('You can now view the NPS Survey in Salesforce: /lightning/r/NPS__c/' + npsSurvey.Id + '/view');

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
    throw e;
}
