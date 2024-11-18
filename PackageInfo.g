#############################################################################
##
##  PackageInfo.g for the package `IO'
##

SetPackageInfo( rec(

PackageName := "IO",
Subtitle := "Bindings for low level C library I/O routines",
Version := "4.9.1",
Date := "18/11/2024", # dd/mm/yyyy format
License := "GPL-3.0-or-later",

##  Information about authors and maintainers.
Persons := [
  rec(
    LastName      := "Neunhöffer",
    FirstNames    := "Max",
    IsAuthor      := true,
    IsMaintainer  := false,
    Email         := "max@9hoeffer.de",
  ),
  rec(
    LastName      := "Horn",
    FirstNames    := "Max",
    IsAuthor      := false,
    IsMaintainer  := true,
    Email         := "mhorn@rptu.de",
    WWWHome       := "https://www.quendi.de/math",
    GitHubUsername:= "fingolfin",
    PostalAddress := Concatenation(
                       "Fachbereich Mathematik\n",
                       "RPTU Kaiserslautern-Landau\n",
                       "Gottlieb-Daimler-Straße 48\n",
                       "67663 Kaiserslautern\n",
                       "Germany" ),
    Place         := "Kaiserslautern, Germany",
    Institution   := "RPTU Kaiserslautern-Landau"
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
README_URL      := Concatenation( ~.PackageWWWHome, "/README.md" ),
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
  HTMLStart := "doc/chap0_mj.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Bindings for low level C library I/O routines",
),

Dependencies := rec(
  GAP := ">=4.12",
  NeededOtherPackages := [],
  SuggestedOtherPackages := [],
  ExternalConditions := []
),

AvailabilityTest := function()
  if not IsKernelExtensionAvailable("io") then
    LogPackageLoadingMessage(PACKAGE_WARNING,
                              ["the kernel module is not compiled, ",
                               "the package cannot be loaded."]);
    return false;
  fi;
  return true;
end,

TestFile := "tst/testall.g",

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
                    "GNU Public License Version 3 or later (at your convenience).\n"
                ),
    )
),

));
