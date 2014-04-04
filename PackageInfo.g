#############################################################################
##  
##  PackageInfo.g for the package `IO'                        Max Neunhoeffer
##
##  (created from Frank Lübeck's PackageInfo.g template file)
##  

SetPackageInfo( rec(

PackageName := "IO",
Subtitle := "Bindings for low level C library IO",
Version := "4.3.1",
Date := "04/04/2014", # dd/mm/yyyy format

##  Information about authors and maintainers.
Persons := [
  rec( 
    LastName      := "Neunhoeffer",
    FirstNames    := "Max",
    IsAuthor      := true,
    IsMaintainer  := false,
    Email         := "neunhoef@mcs.st-and.ac.uk",
    WWWHome       := "http://www-groups.mcs.st-and.ac.uk/~neunhoef/",
    PostalAddress := Concatenation( [
                       "School of Mathematics and Statistics\n",
                       "Mathematical Institute\n",
                       "North Haugh\n",
                       "St Andrews, Fife KY16 9SS\n",
                       "Scotland, UK" ] ),
    Place         := "St Andrews",
    Institution   := "University of St Andrews"
  ),
],

##  Status information. Currently the following cases are recognized:
##    "accepted"      for successfully refereed packages
##    "deposited"     for packages for which the GAP developers agreed 
##                    to distribute them with the core GAP system
##    "dev"           for development versions of packages 
##    "other"         for all other packages
##
# Status := "accepted",
Status := "deposited",

##  You must provide the next two entries if and only if the status is 
##  "accepted" because is was successfully refereed:
# format: 'name (place)'
# CommunicatedBy := "Mike Atkinson (St. Andrews)",
#CommunicatedBy := "",
# format: mm/yyyy
# AcceptDate := "08/1999",
#AcceptDate := "",

PackageWWWHome := "http://neunhoef.github.io/io/",
README_URL     := Concatenation(~.PackageWWWHome, "README"),
PackageInfoURL := Concatenation(~.PackageWWWHome, "PackageInfo.g"),
ArchiveURL     := Concatenation("https://github.com/neunhoef/io/",
                                "releases/download/v", ~.Version,
                                "/io-", ~.Version),
ArchiveFormats := ".tar.gz .tar.bz2",

##  Here you  must provide a short abstract explaining the package content 
##  in HTML format (used on the package overview Web page) and an URL 
##  for a Webpage with more detailed information about the package
##  (not more than a few lines, less is ok):
##  Please, use '<span class="pkgname">GAP</span>' and
##  '<span class="pkgname">MyPKG</span>' for specifing package names.
##  
AbstractHTML := 
  "The <span class=\"pkgname\">IO</span> package, as its name suggests, \
   provides bindings for <span class=\"pkgname\">GAP</span> to the lower \
   levels of Input/Output functionality in the C library.",

PackageDoc := rec(
  BookName  := "IO",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Bindings to low level I/O in the C library",
),

Dependencies := rec(
  GAP := ">=4.5.5",
  NeededOtherPackages := [["GAPDoc", ">= 1.2"]],
  SuggestedOtherPackages := [],
  ExternalConditions := []
),

AvailabilityTest := function()
  if (not("io" in SHOW_STAT())) and
     (Filename(DirectoriesPackagePrograms("io"), "io.so") = fail) then
    #Info(InfoWarning, 1, "IO: kernel IO functions not available.");
    return fail;
  fi;
  return true;
end,

##  *Optional*, but recommended: path relative to package root to a file which 
##  contains as many tests of the package functionality as sensible.
#TestFile := "tst/testall.g",

##  *Optional*: Here you can list some keyword related to the topic 
##  of the package.
Keywords := ["input", "output", "I/O", "C-library", "network", "http",
 "object serialisation", "unpredictable random numbers", "TCP/IP",
 "inter process communication", "background jobs", "parallel skeletons",
 "I/O multiplexing" ]

));


