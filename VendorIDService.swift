//
//  VendorIDService.swift
//  PredixMobileReferenceApp
//
//  Created by Johns, Andy (GE Corporate) on 1/14/16.
//  Copyright © 2016 GE. All rights reserved.
//

/* ****************************
The purpose of this very simple service is to demonstrate the key components of writing a
Predix Mobile client service.

This service takes no parameters, and returns the iOS Vendor Device Id as a JSON object.

There are unit tests for this class in the PredixMobileReferenceAppTests target under the Services group.
**************************** */

import Foundation

// import the PredixMobile framework, so Swift can find the PredixMobile components we'll need
import PredixMobileSDK

// services must implement the ServiceProtocol protocol.
// As this protocol is defined as Obj-C compatible, the implementer must be an Obj-C compatible class.
@objc class VendorIDService: NSObject, ServiceProtocol {
    /* ****************************
    ServiceProtocol's properties and methods are all defined as static, and no class implementation of your service is ever created.
    This is a purposeful architectural decision. Services should be stateless and interaction with them ephemeral. A static
    object enforces this direction.
    **************************** */

    // the serviceIdentifier property defines first path component in the URL of the service.
    static var serviceIdentifier: String {get { return "vendorid" }}

    /* ****************************
    performRequest is the meat of the service. It is where all requests to the service come in.
    
    The request parameter will contain all information the caller has provided for the request, this will include the URL,
    the HTTP Method, and in the case of a POST or PUT, any HTTP body data.

    The nature of services are asynchronous. So this method has no return values, it communicates with its caller through three
    blocks or closures. These three are the parameters responseReturn, dataReturn, and requestComplete. This follows the general
    nature of a web-based HTTP interaction.
    
    responseReturn -- generally every call to performRequest should call responseReturn once, and only once. The call requires an
    NSHTTPResponse object, and a default object is provided as the "response" parameter. The response object can be returned directly,
    or can be used as a container for default values, and a new NSHTTPResponse can be built from it. The default response parameter's
    status code is 200 (OK), so error conditions will not return the response object unaltered. (See the respondWithErrorStatus methods,
    and the createResponse method documentation below for helpers in creating other response objects.)
    
    dataReturn -- Services that return data, and not just a status code will use the dataReturn parameter to return data. Generally
    this block will be called once, however it could be called multiple times to return particularly large amounts of data in a
    chunked fashion. Again, this behavior follows general web-based HTTP interaction. If used, the dataReturn block should be called after
    the responseReturn block is called, and before the responseComplete block is called.
    
    requstComplete -- this block indicates to the caller that the service has completed processing, and the call is complete. The requestComplete
    block must be called, and it must be called only once per performRequest call. Once the requestComplete block is called, no additional 
    processing should happen in the service, and no other blocks should be called.
    **************************** */
    static func performRequest(_ request: URLRequest, response: HTTPURLResponse, responseReturn : @escaping responseReturnBlock, dataReturn : @escaping dataReturnBlock, requestComplete: @escaping requestCompleteBlock) {

        // First let's examine the request. In this example, we're going to expect only a GET request, and the URL path should only be the serviceIdentifier

        // we'll use a guard statement here just to verify the request object is valid. The HTTPMethod and URL properties of a NSURLRequest
        // are optional, and we need to ensure we're dealing with a request that contains them.

        guard let url = request.url else {
            /* ****************************
             if the request does not contain a URL or a HTTPMethod, then we return a error. We'll also return an error if the URL
             does not contain a path. In a normal interaction this would never happen, but we need to be defensive and expect anything.
            
             we'll use one of the respondWithErrorStatus methods to return an error condition to the caller, in this case,
             a status code of 400 (Bad Request).
            
             Note that the respondWithErrorStatus methods all take the response object, the reponseReturn block and the requestComplete
             block. This is because the respondWithErrorStatus constructs an appropriate NSHTTPURLResponse object, and calls
             the reponseReturn and requestComplete blocks for you. Once a respondWithErrorStatus method is called, the performRequest
             method should not continue processing and should always return.
            **************************** */
            self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
            return
        }

        /* ****************************
         Now that we know we have a path and method string, let's examine them for our expected values.
         For this example we'll return an error if the url has any additional path or querystring parameters.
         We'll also return an error if the method is not the expected GET HTTP method. The HTTP Status code convention
         has standard codes to return in these cases, so we'll use those.
        **************************** */

        /* ****************************
         Path in this case should match the serviceIdentifier, or "vendorid". We know the serviceIdentifier is all
         lower case, so we ensure the path is too before comparing.
         
         We use the serviceIdentifier property here rather than the string "vendorid" as a general best practice of
         avoiding hard-coded strings in multiple places.
        
         In addition, we expect the query string to be nil, as no query parameters are expected in this call.
        
         In your own services you may want to be more lenient, simply ignoring extra path or parameters.
        **************************** */
        if url.path.lowercased() != "/\(self.serviceIdentifier)" || url.query != nil {
            // In this case, if the request URL is anything other than "http://pmapi/vendorid" we're returning a 400 status code.
            self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
            return
        }

        // now that we know our path is what we expect, we'll check the HTTP method. If it's anything other than "GET"
        // we'll return a standard HTTP status used in that case.

        if request.httpMethod != "GET" {
            // According to the HTTP specification, a status code 405 (Method not allowed) must include an Allow header containing a list of valid methods.
            // this  demonstrates one way to accomplish this.
            let headers = ["Allow": "GET"]

            // This respondWithErrorStatus overload allows additional headers to be passed that will be added to the response.
            self.respondWithErrorStatus(Http.StatusCode.methodNotAllowed, response, responseReturn, requestComplete, headers)
            return
        }

        // Now we know that our path and method were correct, and we've handled error conditions, we get the device's vendor id.
        if let vendorId = UIDevice.current.identifierForVendor {
            // Let's return the vendorId as a JSON object, a dictionary that contains the key "vendorId" and the value of the id itself.
            // We could create this many ways, but here we'll use the Apple SDK's JSON serialization:

            let returnDictionary = ["vendorId": vendorId.uuidString]

            // NSJSONSerialization.dataWithJSONObject can throw, so we'll do this in a do/try/catch statement.
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: returnDictionary, options: JSONSerialization.WritingOptions(rawValue: 0))

                // Now our jsonData object contains a serialized JSON dictionary ready for consumption by the caller.

                // Our service call is complete, now we call our blocks, in order.

                // the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                responseReturn(response)

                // we return the JSON object
                dataReturn(jsonData)

                // An inform the caller the service call is complete
                requestComplete()

                // We don't need this return here, since we don't have any other code below, but in a more complex service call you may.
                // After requestComplete is called, you should always ensure no other code is executed in the method.
                return
            } catch let error {
                // Log the error
                Logger.error("\(#function): JSON Serialization error: \(error)")

                // And return a 500 (Internal Server Error) status code reponse.
                self.respondWithErrorStatus(.internalServerError, response, responseReturn, requestComplete)
                return
            }
        } else {
            // since identifierForVendor is an optional, we need to handle what happens if the value isn't returned.
            // This would be very unusual, but again for this demo we're using full defensive coding practices.

            // Since the iOS environment should always have the identifierForVendor, it being nil is a odd error,
            // one that warrents a generic 500 (Internal Server Error) status code reponse.

            self.respondWithErrorStatus(.internalServerError, response, responseReturn, requestComplete)
            return
        }

    }

    /* ****************************
    The methods "registered" and "unregistered" are optional in the ServiceProtocol protocol. They are called when your service
    is registered/unregistered in the ServiceRouter. The ServiceRouter controls which services are available in the system. 
    When a service is registered it is then capable of receiving requests. When it is unregistered it will no longer receive requests.
    While services themselves are stateless, there may be times when they utilize non-stateless components, or need to prepare 
    something in the system environment prior to being used. These methods allow for that type of interaction.
    For this example service we will not use them.
    **************************** */
    //static func registered(){}
    //static func unregistered(){}
}
