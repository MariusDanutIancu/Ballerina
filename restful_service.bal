import ballerina/http;
import ballerinax/docker;

//@docker:Config {
//    registry:"kronos.tests.com",
//    name:"restful_service",
//    tag:"v1.0"
//}

//@docker:Expose{}
endpoint http:Listener listener { port:9090 };

map<json> testsMap;

@http:ServiceConfig { basePath: "/myservice" }
service<http:Service> myservice bind listener {

    @http:ResourceConfig { methods: ["GET"], path: "/test/{testId}" }
    findTest(endpoint client, http:Request req, string testId) {
        
        json? payload = testsMap[testId];
        if (payload == null) { payload = "Test : " + testId + " cannot be found."; }

        http:Response response;
        response.setJsonPayload(untaint payload);

        _ = client->respond(response);
    }

    @http:ResourceConfig { methods: ["POST"], path: "/test" }
    addTest(endpoint client, http:Request req) {
        
        json testReq = check req.getJsonPayload();
        string testId = testReq.Test.ID.toString();
        testsMap[testId] = testReq;

        json payload = { status: "Test Created.", testId: testId };
        
        http:Response response;
        response.setJsonPayload(untaint payload);
        response.setHeader("Location", "http://localhost:9090/myservice/test/" + testId);
        response.statusCode = 201;

        _ = client->respond(response);
    }

    @http:ResourceConfig { methods: ["PUT"], path: "/test/{testId}"}
    updateTest(endpoint client, http:Request req, string testId) {
        
        json updatedTest = check req.getJsonPayload();
        json existingTest = testsMap[testId];

        if (existingTest != null) {
            existingTest.Test.Name = updatedTest.Test.Name;
            existingTest.Test.Description = updatedTest.Test.Description;
            testsMap[testId] = existingTest;
        } else {
            existingTest = "Test : " + testId + " cannot be found.";
        }

        http:Response response;
        response.setJsonPayload(untaint existingTest);
        
        _ = client->respond(response);
    }

    @http:ResourceConfig { methods: ["DELETE"], path: "/test/{testId}" }
    cancelTest(endpoint client, http:Request req, string testId) {

        _ = testsMap.remove(testId);

        json payload = "Test : " + testId + " removed.";
        http:Response response;
        response.setJsonPayload(untaint payload);

        _ = client->respond(response);
    }
}