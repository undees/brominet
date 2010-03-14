# Getting Brominet to work with YOUR app

How to go about integrating Brominet into your own applications.

It is recommended to look at
[**JustPlayed**](http://github.com/textarcana/justplayed) in order to
better understand how to use Ian's
[Encumber](http://github.com/textarcana/justplayed/blob/master/lib/encumber.rb)
module. 

## Download Dependencies
  
      cd MY_PROJECT
  
      git clone git://github.com/textarcana/brominet brominet
      git clone git://github.com/undees/cocoahttpserver server
      git clone git://github.com/undees/asi-http-request asi-http-request
  
  
## Create a Brominet build target

1. In XCode, duplicate your application's main target.  By convention the target is named "Brominet."

2. Add a new group named `Brominet` to your project.  Link the `Brominet` group only with Brominet target.

3. Drag the needed objective-c files from `MY_PROJECT/brominet` (in
  the Finder), into the `Brominet` group. Use the list below as a guide
  as to which files are needed. Or just put Ian's project side by side
  with yours, and then make sure to copy over the same files. (list of
  which files TK). Make sure the path for all the files is "relative to
  project."

4. Add a new `CocoaHTTPServer` group. Link the `CocoaHTTPServer` group,  only with the Brominet target.
  
5. Drag the needed objective-c files from `MY_PROJECT/server`, into the `CocoaHTTPServer` group.

4. Add a new `ASIHTTPRequest` group. Link the `ASIHTTPRequest` group,  only with the Brominet target.
  
5. Drag the needed objective-c files from `MY_PROJECT/server`, into the `ASIHTTPRequest` group.

## Configure the Brominet target

Do a "Get Info" on the brominet Brominet target, and in Build section, do the following:

  1. add this to the Header Search Path: 

      /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/usr/include/libxml2;

   2. link the libxml2 library to your Frameworks folder

   3. add the preprocessor macro (GCC_PREPROCESSOR_DEFINITIONS) with value BROMINET_ENABLED;

   4. make sure GCC_C_LANGUAGE_STANDARD is c99 or gnu99

## Include the dependencies in project

 Now update the app delegate with some ifdefs.  The easiest way to see
 which files are required, may be to look at the app delegate in
 [Ian Dees' **JustPlayed** example app,](http://github.com/textarcana/justplayed).
 
 At a minimum, do the following.

 1. add the ifdefs HTTP server include, and invocation to `AppDelegate.h`

 1. add the ifdef for headers to `AppDelegate.m`

  2. add the ifdef to launch the server to `AppDelegate.m`

  3. add the ifdef stop the server and garbage collect, to `AppDelegate.m`

## Troubleshooting your Brominet installation

Because Brominet is integrated with your app, it's important to be
aware of all the dependencies for both Brominet and your own code.

### ASIHTTPRequest  and Reachability.h versions

Note that in Ian's JustPlayed example, ASIHTTPRequest uses the Reachability 1.5 API. Apple has
since upgraded the Reachability library to 2.0, and [ASIHTTPRequest now supports](http://allseeing-i.com/ASIHTTPRequest/Setup-instructions) both versions of the Reachability API. Although the new
version is backward compatible, be aware that newer applications may
already be including Reachability 2.0.

## Driving Brominet from a Ruby process

First, to see Brominet in action, take a look at the Cucumber
functional tests for iPhone that
[Ian Dees presented at OSCON 2009](http://www.oscon.com/oscon2009/public/schedule/detail/8073).

### Instant gratification: test drive the JustPlayed example app

If you just want to test drive Brominet, you can follow the instructions in
[my fork.](http://github.com/textarcana/justplayed/doc/install)

I'm using
 [**my fork of the JustPlayed example application**](http://github.com/textarcana/justplayed)
 as an example.  **The procedure outline here is the same for any app
 into which you've installed Brominet.**

If you build and start the simulator with
[**my fork of the JustPlayed example application**](http://github.com/textarcana/justplayed),
then you should notice a new service running on port 50000.   You can
then control the app in the simulator, by sending chunks of XML over
HTTP.  This is all handled by Ian's `encumber.rb` library.

### Remote-controlled iPhone apps

If you build the Brominet-enabled app onto an iPhone, then you can
control the iPhone over a wi-fi network.  

To find your iPhone's IP address, follow these instructions.

1. Assuming you are already connected to a wi-fi network, go to Settings > Wi-Fi. 

2. Tap the name of the network to which you are currently connected (the one with a check mark next to
it).

3. In the DHCP tab, note the IP address of your device.

4. Assuming your computer is connected to the same wi-fi network, you
can now connect to the Brominet Web service on your iPhone, on port
50000.

### Test-driving Brominet from the IRB

Here is how to use the IRB to call the app directly and dump the
XML of the GUI.  Type or paste the following 3 commands into the IRB.

    load 'lib/encumber.rb'

    @gui = Encumber::GUI.new 'localhost'
     
    File.open('encumber_gui.xml', 'w') {|f| f.write(@gui.dump) }

Then open `encumber_gui.xml` in an XML editor like Firefox or XML
Spy.  Once you work out which XPaths correspond to the buttons in your
app, you can start tapping buttons using `Encumber::GUI#press`

    @gui.press '//xpath/to/button'

If you have deployed a Brominet-enabled app on an iPhone, then you can
use the same procedure to connect to it.

    @gui = Encumber::GUI.new '10.0.1.23'

Finally, if you start the the
[IRB](http://mislav.uniqpath.com/poignant-guide/book/expansion-pak-1.html)
in the root of my fork of JustPlayed, then you can use the convenience
methods that are implemented in
[**my `.irbc` file**](http://github.com/textarcana/justplayed/blob/master/.irbrc).



## Sources
  
  1. <http://code.google.com/p/bromine/wiki/UsingBromine>
  
  2. <http://forums.pragprog.com/forums/134/topics/3166>
  
  2. <http://github.com/textarcana/justplayed/tree/master/doc/install/>
  
  3. <http://allseeing-i.com/ASIHTTPRequest>
  
See also <http://delicious.com/thefangmonster/brominet>
 

