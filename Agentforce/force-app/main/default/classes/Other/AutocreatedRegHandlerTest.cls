@isTest
private class AutocreatedRegHandlerTest {
static testMethod void testCreateAndUpdateUser() {
    AutocreatedRegHandler1698146387021 handler = new AutocreatedRegHandler1698146387021();
    Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
        'testFirst testLast', 'testuser@example.org', null, 'testuserlong', 'en_US', 'facebook',
        null, new Map<String, String>{'language' => 'en_US'});
        
    User u = handler.createUser(null, sampleData);
    System.assertEquals('testuserlong@myorg.com', u.userName);
    System.assertEquals('testuser@example.org', u.email);
    System.assertEquals('testLast', u.lastName);
    System.assertEquals('testFirst', u.firstName);
    System.assertEquals('testuser', u.alias);
    insert(u);
    String uid = u.id;
    
    sampleData = new Auth.UserData('testNewId', 'testNewFirst', 'testNewLast',
        'testNewFirst testNewLast', 'testnewuser@example.org', null, 'testnewuserlong', 'en_US', 'facebook',
        null, new Map<String, String>{});
    handler.updateUser(uid, null, sampleData);
    
    User updatedUser = [SELECT userName, email, firstName, lastName, alias FROM user WHERE id=:uid];
    System.assertEquals('testuserlong@myorg.com', updatedUser.userName);
    System.assertEquals('testnewuser@example.org', updatedUser.email);
    System.assertEquals('testNewLast', updatedUser.lastName);
    System.assertEquals('testNewFirst', updatedUser.firstName);
    System.assertEquals('testuser', updatedUser.alias);
}
}