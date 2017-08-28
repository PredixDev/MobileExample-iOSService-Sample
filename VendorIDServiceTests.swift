//
//  VendorIDServiceTests.swift
//  PredixMobileReferenceApp
//
//  Created by Johns, Andy (GE Corporate) on 1/14/16.
//  Copyright © 2016 GE. All rights reserved.
//

/* ****************************
Unit tests are a key component in all software development. In a services-based architecture
they are critical to ensure the services are working properly, and changes do not negatively impact
consumers of the service. 

Many times services may be entirely written using unit tests to exercise the code and do
development debugging. The first time a webapp interacts with your service may be during
integration testing.

There are many ways to write unit tests, and many methodologies of testing. For this example,
we'll focus on ensuring tests are both positive and negative, and demonstrate some of the
helpers we've included in the example PredixMobileReferenceAppTests target.
**************************** */

import XCTest

// We need to import our app. We use the @testable attribute in order to call internal methods, which can be helpful in testing some scenarios.
// In this simple example, we don't need to, but it's a good practice to remember.
@testable import PredixMobileiOS

// We also need to import the Predix Mobile SDK Framework.
import PredixMobileSDK

class VendorIDServiceTests: XCTestCase {

    // setUp, tearDown, testExample, and testPerformanceExample are all included in the default XCode Unit Test template.
    // They are left here unaltered just for orientation and reference.

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    // We'll start our VendorIDService tests here. Obviously we could have deleted the unused testExample, and testPerformance example.

    // The file ServiceProtocolTestHelper extends the XCTest class with some helpful methods for testing Predix Mobile serviceProtocol implementing classes.

    func testGetVendorId() {
        // first a happy-case test. We'll call the VendorIdService and get a return. Simple cases like this can use a lot of the defaults from ServiceProtocolTestHelper.

        // With this serviceTester overload we provide our service calls, the path to call, and the status code we expect back from the service.
        // There are also optional blocks we can provide to allow for detailed examination of the NSURLResponse object, and any returned NSData.

        // we could just construct a hardcoded path "http://pmapi/vendorid" but if constants or configuration variables exist, it's better to use them.
        // API_SCHEME is a constant "http"
        // PredixMobilityConfiguration.API_HOST is the currently configured host, which defaults to "pmapi".
        let path = "\(Http.scheme)://\(PredixMobilityConfiguration.apiHostname)/vendorid"

        // As service calls are asyncronous this entire interaction is wrapped in an XCTest expectation, and the timeout for expectations is 20 seconds.
        // You can create new expectations and fulfill them in the testResponse and/or testData blocks.
        // let's create an expectation, that we'll fulfill in the data block when we examine the return data. This will ensure our call actually does return data.
        let dataExpectation = self.expectation(description: "\(#function): testData closure called expectation.")

        // serviceTester registers the service in the Service Router, executes the request, and examines the returned status code.
        // If provided the testResponse and testData blocks are be called.
        // If the service does not call requestComplete within 20 seconds, or the returned status code is not the expected status code the test will fail.
        self.serviceTester(VendorIDService.self, path: path, expectedStatusCode: .ok, testResponse: nil, testData: { (data: Data) -> Void in

            // let's de-serialize the data into our exepected dictionary.
            //  NSJSONSerialization.JSONObjectWithData can throw so we wrap this in a do/try/catch
            do {
                let deserializedObj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))

                // so we have an object, but we need to ensure it's the type of object we expect. 
                // We're expecting a dictionary with a key and value both a string, so we'll try an optional casting
                if let dict = deserializedObj as? [String: String] {
                    // yes, it's the correct type.
                    // now check that we have the expected key
                    XCTAssertNotNil(dict["vendorId"], "key \"vendorId\" not found in return dictionary: \(dict)")

                    // now check that the value associated with the key matches what we expect: for this simple example service, the device's vendor id.
                    XCTAssertEqual(dict["vendorId"], UIDevice.current.identifierForVendor!.uuidString)

                    // Yes, the XCTAssertEqual renders the XCTAssertNotNil redundant, but in more complicated testing scenarios the messages associated
                    // with a test failure may be critical to knowing where a test failed, and debugging.
                } else {
                    XCTAssertTrue(false, "deserializedObj was not the expected type: \(deserializedObj)")
                }
            } catch let error {
                XCTAssertTrue(false, "JSON deserialization of the returned data failed: \(error)")
            }
            // fulfill our expectation.
            dataExpectation.fulfill()
        })
    }

    // Tests our return status when a path contains more than we expect
    func testBadURL_ExtraPathComponents() {
        // create our "bad" URL example, with additional path after the "vendorid" part. This should return a 400 (Bad Request) error
        let path = "\(Http.scheme)://\(PredixMobilityConfiguration.apiHostname)/vendorid/some/additional/path"

        // now we run the service tester. Since we're expecting an error, we don't need a testData block, and in this case 
        // we don't need to examine anything extra in the testResponse block so we won't include them.
        self.serviceTester(VendorIDService.self, path: path, expectedStatusCode: .badRequest, testResponse: nil, testData: nil)
    }

    // Tests our return status when a path contains more than we expect
    func testBadURL_Querystring() {
        // create our "bad" URL example, with a unnecessary query string
        let path = "\(Http.scheme)://\(PredixMobilityConfiguration.apiHostname)/vendorid?query=string"

        // now we run the service tester. Since we're expecting an error, we don't need a testData block, and in this case
        // we don't need to examine anything extra in the testResponse block so we won't include them.
        self.serviceTester(VendorIDService.self, path: path, expectedStatusCode: .badRequest, testResponse: nil, testData: nil)
    }

    // Obviously we could test a lot more conditions. A good set of unit tests should try for at least 80-90% code coverage.
    // After all, the more code coverage you have, the better able you are to ensure everything is working as expected.

    // But for this example, we'll end with this test that demonstrates how you can use the testResponse block to ensure any
    // custom headers are returning as expected, and also uses a serviceTester overload that takes a NSURLRequest parameter
    // instead of a simple path.

    func testBadHTTPMethod() {

        // Our request url string
        let path = "\(Http.scheme)://\(PredixMobilityConfiguration.apiHostname)/vendorid"

        // create a mutable request:
        var request = URLRequest(url: URL(string: path)!)

        // change the HTTPMethod to POST
        request.httpMethod = "POST"

        // now we run the service tester. Since we're expecting an error, and our service only returns data when there are no errors, we 
        // don't need a testData block. But, we will include a testResponse block to ensure our headers are being added properly.
        self.serviceTester(VendorIDService.self, request: request, expectedStatusCode: .methodNotAllowed, testResponse: { (response: URLResponse) -> Void in

            // we need to cast the reponse. We could be more defensive here by optionally casting and doing an XCTAssert if it failed...

            let httpResponse = response as! HTTPURLResponse

            // now check that our expected "Allow" header is there, and is the value we expect.
            XCTAssertEqual(httpResponse.allHeaderFields["Allow"] as? String, "GET", "Allow header was not as expected")

            }, testData: nil)

    }

}
