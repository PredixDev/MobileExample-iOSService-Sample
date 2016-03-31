## Predix Mobile iOS Service Example

This repo contains a Predix Mobile iOS service example that demonstrates a simple native service implementation.

### Prerequisites

It is assumed you already have a Predix Mobile service installation, have installed the Predix Mobile pm command line tool, and have installed a Predix Mobile iOS Container, following the Getting Started examples for those repos.

It is also assumed you have a basic knowledge of mobile iOS development using XCode and Swift.

### Step 1 - Integrate the example code

  a. Add the `VendorIDService.swift` and `VendorIDServiceTests.swift` files from this repo to your container project.

  b. Open your Predix Mobile container app project. 

  c. In the Project Manager in left-hand pane, expand the PredixMobileReferenceApp project, then expand the PredixMobileReferenceApp group. Within that group, expand the Classes group. 

  d. In this group, create a group called "Services". 

  e. Add the file `VendorIDService.swift` to this group, either by dragging from Finder, or by using the Add Files dialog in XCode. When doing this, ensure the `VendorIDService.swift` file is copied to your project, and added to your PredixMobileReferenceApp target.

  f. Add a "Services" group to your PredixMobileReferenceAppTests group. 

  g. Add the `VendorIDServiceTests.swift` file to this group, ensuring that you copy the file, and add it to the `PredixMobileReferenceAppTests` unit testing target.

### Step 2 - Register the new service

The `VendorIDService.swift` file contains all the code needed for the example service, however, you must register the service in the container in order for it to be available to the web app. In order to do this, add a line of code to `AppDelegate`.

In the `AppDelegate.swift` file, navigate to the `application: didFinishLaunchingWithOptions:` method. In this method, and look for a line that looks like this:

    PredixMobilityConfiguration.loadConfiguration()

Directly after that line, add the following:

    PredixMobilityConfiguration.additionalBootServicesToRegister = [VendorIDService.self]

This informs the iOS Predix Mobile SDK framework to load your new service when the app starts, thus making it available to your webapp.

#### Step 3 - Review the code

The Swift files you added to your container are heavily documented. Read through these for a full understanding of how they work, and what they are doing.

The comments describe creating an implemenation of the `ServiceProtocol` protocol, handling requests to the service with this protocol, and returning data or error status codes to callers.

#### Step 4 - Run the unit tests

Unit tests are a key component in all software development. In a services-based architecture like Predix Mobile,
they are critical to ensure the services are working properly, and changes do not negatively impact
consumers of the service.

Review and run the unit tests that you added to the project.

#### Step 5 - Call the service from a webapp

Your new iOS client service is exposed through the service identifier "vendorid". Calling _http://pmapi/vendorid_ from a web app calls this service.

A simple demo web app is provided in the `demo-webapp` directory in the git repo.

