#############################################################################
##
##  PackageInfo.g for the package `IO'
##

SetPackageInfo( rec(

PackageName := "IO",
Subtitle := "Bindings for low level C library I/O routines",
Version := "4.4.6",
Date := "08/03/2016", # dd/mm/yyyy format

##  Information about authors and maintainers.
Persons := [
  rec(
    LastName      := "Neunhöffer",
    FirstNames    := "Max",
    IsAuthor      := true,
    IsMaintainer  := false,
    Email         := "max@9hoeffer.de",
    WWWHome       := "http://www-groups.mcs.st-and.ac.uk/~neunhoef",
    PostalAddress := Concatenation( [
                       "Gustav-Freytag-Straße 40\n",
                       "50354 Hürth\n",
                       "Germany" ] ),
    #Place         := "St Andrews",
    #Institution   := "University of St Andrews"
  ),
  rec(
    LastName      := "Horn",
    FirstNames    := "Max",
    IsAuthor      := false,
    IsMaintainer  := true,
    Email         := "max.horn@math.uni-giessen.de",
    WWWHome       := "http://www.quendi.de/math",
    PostalAddress := Concatenation(
                       "AG Algebra\n",
                       "Mathematisches Institut\n",
                       "Justus-Liebig-Universität Gießen\n",
                       "Arndtstraße 2\n",
                       "35392 Gießen\n",
                       "Germany" ),
    Place         := "Gießen",
    Institution   := "Justus-Liebig-Universität Gießen"
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

SourceRepository := rec(
    Type := "git",
    URL := "https://github.com/gap-packages/io",
),
IssueTrackerURL := Concatenation( ~.SourceRepository.URL, "/issues" ),
PackageWWWHome  := "https://gap-packages.github.io/io",
README_URL      := Concatenation( ~.PackageWWWHome, "/README" ),
PackageInfoURL  := Concatenation( ~.PackageWWWHome, "/PackageInfo.g" ),
ArchiveURL      := Concatenation( ~.SourceRepository.URL,
                                 "/releases/download/v", ~.Version,
                                 "/io-", ~.Version ),
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
  LongTitle := "Bindings for low level C library I/O routines",
),

Dependencies := rec(
  GAP := ">=4.7.4",
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
 "I/O multiplexing" ],

AutoDoc := rec(
    TitlePage := rec(
        Copyright := Concatenation(
                    "&copyright; 2005-2014 by Max Neunhöffer<P/>\n",
                    "\n",
                    "This package may be distributed under the terms and conditions of the\n",
                    "GNU Public License Version 3 or later.\n"
                ),
    )
),

));
