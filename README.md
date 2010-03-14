# Integrating Brominet into your own application

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

### Include the dependencies in project

 Now update the app delegate with some ifdefs.  The easiest way to see
 which files are required, may be to look at the app delegate in
 [Ian Dees' **JustPlayed** example app,](http://github.com/textarcana/justplayed).
 
 At a minimum, do the following.

 1. add the ifdefs HTTP server include, and invocation to `AppDelegate.h`

 1. add the ifdef for headers to `AppDelegate.m`

  2. add the ifdef to launch the server to `AppDelegate.m`

  3. add the ifdef stop the server and garbage collect, to `AppDelegate.m`

## Troubleshooting

### ASIHTTPRequest  and Reachability.h versions

Note that in Ian's JustPlayed example, ASIHTTPRequest uses the Reachability 1.5 API. Apple has
since upgraded the Reachability library to 2.0, and [ASIHTTPRequest now supports](http://allseeing-i.com/ASIHTTPRequest/Setup-instructions) both versions of the Reachability API. Although the new
version is backward compatible, be aware that newer applications may
already be including Reachability 2.0.

## Sources
  
  1. <http://code.google.com/p/bromine/wiki/UsingBromine>
  
  2. <http://forums.pragprog.com/forums/134/topics/3166>
  
  2. <http://github.com/textarcana/justplayed/tree/master/doc/install/>
  
  3. <http://allseeing-i.com/ASIHTTPRequest>
  
See also <http://delicious.com/thefangmonster/brominet>
 
