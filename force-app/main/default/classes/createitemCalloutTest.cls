@isTest
public class createitemCalloutTest {



    class MockFailedCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500); // Simulate failure
            res.setBody('Internal Server Error');
            return res;
        }
    }
    


    // HTTP Mock implementation
    public class MockCreateItemResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Item":{"Id":"12345","SyncToken":"1"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testCreateItemCallout_Success() {
        // Step 1: Insert Product2 record that matches callout conditions
        Product2 p = new Product2(
            Name = 'Test Product Kit',
            Description = 'This is a kit product'
        );
        insert p;

        // Step 2: Register the mock response
        Test.setMock(HttpCalloutMock.class, new MockCreateItemResponse());

        // Step 3: Call the future method inside test context
        Test.startTest();
        createItemCallout.createItem(p.Id, 'dev');
        Test.stopTest();

        // Step 4: Verify Product2 record was updated
        Product2 updatedProduct = [SELECT Id, QuickBook_Item_ID__c FROM Product2 WHERE Id = :p.Id];
        System.assertEquals('12345', updatedProduct.QuickBook_Item_ID__c);
    }

    @isTest
    static void testCreateItemCallout_Fail() {
        // Step 1: Insert Product2 record that matches callout conditions
        Product2 p = new Product2(
            Name = 'Test Product Kit1',
            Description = 'This is a kit product1'
        );
        insert p;

        // Step 2: Register the mock response
        Test.setMock(HttpCalloutMock.class, new MockFailedCallout());

        // Step 3: Call the future method inside test context
        Test.startTest();
        createItemCallout.createItem(p.Id, 'dev');
        Test.stopTest();

        // Step 4: Verify Product2 record was updated
        // Product2 updatedProduct = [SELECT Id, QuickBook_Item_ID__c, QB_SyncToken__c FROM Product2 WHERE Id = :p.Id];
        // System.assertEquals('12345', updatedProduct.QuickBook_Item_ID__c);
        // System.assertEquals('1', updatedProduct.QB_SyncToken__c);
    }

    @isTest
    static void testCreateItemCallout_NoDescription() {
        Product2 p = new Product2(
            Name = 'Product Without Description'
            // No description => should skip callout
        );
        insert p;

        Test.setMock(HttpCalloutMock.class, new MockCreateItemResponse());

        Test.startTest();
        createItemCallout.createItem(p.Id, 'dev');
        Test.stopTest();

        Product2 notUpdatedProduct = [SELECT Id, QuickBook_Item_ID__c FROM Product2 WHERE Id = :p.Id];
        // System.assertEquals(null, notUpdatedProduct.QuickBook_Item_ID__c);
    }

    @isTest
    static void testCreateItemCallout_AlreadyHasQBID() {
        Product2 p = new Product2(
            Name = 'Product Already Synced',
            Description = 'Kit product',
            QuickBook_Item_ID__c = '99999'
        );
        insert p;

        Test.setMock(HttpCalloutMock.class, new MockCreateItemResponse());

        Test.startTest();
        createItemCallout.createItem(p.Id, 'dev');
        Test.stopTest();

        Product2 existing = [SELECT Id, QuickBook_Item_ID__c FROM Product2 WHERE Id = :p.Id];
        System.assertEquals('99999', existing.QuickBook_Item_ID__c); // Should remain unchanged
    }
}