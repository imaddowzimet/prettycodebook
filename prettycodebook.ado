capture program drop prettycodebook
program define prettycodebook

syntax varlist, name(name) datasetname(string) [function(name) statname(string)]

* TO DO: Decide if we want to keep this program name
* TO DO: Take another pass at style sheet; also, delete items that are just 
* carryover from markstat and aren't used. 
* TO DO: Create help file, toc, and pkg file. 
* TO DO (long term): Probably want to add an option so that someone can use their own 
* style sheet if they want (or add to existing style sheet)
* Could also have a default page name, though that seems trickier looking
* at the documentation for syntax.
* TO DO: There's quite a lot of repetition across subprograms; these could 
* probably be written into functions to make everything more readable.
* NOTE: some additional TODOs are written throughout file.

* Create codebook folder at root of wd, if it doesn't already exist
cap mkdir Codebook
cap mkdir "Codebook/Files"

* Create markdown file
tempname myfile
file open `myfile' using "Codebook/`name'.md", write replace

* Copy in style sheet from GitHub 
copy "https://raw.githubusercontent.com/imaddowzimet/Misc/master/codebook.css" "Codebook/Files/codebook.css", replace

* Link to style sheet
file write `myfile' `"<link rel="stylesheet" href="Files/codebook.css">  "' _n

* Write out header info 
* TO DO: Make the description field editable as part of the syntax (but keep current text as default option if not specified)
file write `myfile' `"<div class="header">  "' _n
file write `myfile' `"<h1>`datasetname'</h1>  "' _n
file write `myfile' `"<div class = "description"> This is the online codebook for `datasetname'. Click any variable for more details, or filter to a selection of variables. </div>  "' _n
file write `myfile' `"</div>   "' _n

* Javascript for search (source: https://www.w3schools.com/howto/howto_js_filter_lists.asp)
file write `myfile' `"<script>  "' _n
file write `myfile' `"function myFunction() {  "' _n
file write `myfile' `"  var input, filter, ul, li, a, i, txtValue;  "' _n
file write `myfile' `"  input = document.getElementById('myInput');  "' _n
file write `myfile' `"  filter = input.value.toUpperCase();  "' _n
file write `myfile' `"  ul = document.getElementById("myUL");  "' _n
file write `myfile' `" li = ul.getElementsByTagName('li');  "' _n
file write `myfile' `"  for (i = 0; i < li.length; i++) {  "' _n
file write `myfile' `"    a = li[i].getElementsByTagName("a")[0];  "' _n
file write `myfile' `"   txtValue = a.textContent || a.innerText;  "' _n
file write `myfile' `"    if (txtValue.toUpperCase().indexOf(filter) > -1) {  "' _n
file write `myfile' `"      li[i].style.display = "";  "' _n
file write `myfile' `"    } else {  "' _n
file write `myfile' `"      li[i].style.display = "none";  "' _n
file write `myfile' `"    }  "' _n
file write `myfile' `"  }  "' _n
file write `myfile' `"}  "' _n
file write `myfile' `"</script>  "' _n

* Search bar 
file write `myfile' `"<input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for variables">  "'  _n  
file write `myfile' "" _n
file write `myfile' "" _n

* Header
file write `myfile' "## List of variables in dataset:  " _n

* Start of list that can be filtered by search bar
file write `myfile' `"<ul id="myUL">"' _n

* Create link for a page with all variables detailed info in one 
file write `myfile' `"<li><a href="Files/allvars.html"><strong>All Variables</strong>: See all variable details on one page</a></li>"' _n

* Record names of codebook sections, if any are in the [section] characteristic
ds `varlist', has(char section)
local sectionvars `r(varlist)'
if !missing("`sectionvars'") {
local sectionlist 
foreach myvar of varlist `sectionvars' {
    
	local sectionname: char `myvar'[section]
	if !regexm(`"`sectionlist'"', `"`sectionname'"') {
		local sectionlist `"`sectionlist' "`sectionname'""'
	}

}
}

* TO DO: Note that the code above breaks if the section names have parentheses;
* so we either need to catch that earlier or program in a fix. 

* If it does have section names, write out variables in section blocks
if !missing(`"`sectionlist'"') {
local hassections yes
foreach mysection of local sectionlist {
	file write `myfile' "### `mysection':  " _n

	foreach myvar of varlist `sectionvars' {
		 di "`myvar'"
		 local varlabel: variable label `myvar'
	     local sectionlabel: char `myvar'[section]
         if "`sectionlabel'" == "`mysection'" {
	     
			 file write `myfile' `"<li><a href="Files/`myvar'.html"><strong>`myvar'</strong>: `varlabel'</a></li>"' _n
	         if missing("`function'") {
				qui htmlpagevar `myvar'
			 }
	         if !missing("`function'") {
				qui htmlpagevar `myvar', function(`function') statname("`statname'")
			 }			 
         }
	}
}  
}

* For any variables not in section blocks, put them in a generic section
* (this only gets a label if there are any sections)
ds `varlist', not(char section)
local nonsectionvars `r(varlist)'
if "`hassections'" == "yes" {
	file write `myfile' "### Variables not assigned to a section:  " _n

}
foreach myvar of varlist `nonsectionvars' {
	 local varlabel: variable label `myvar'
	 
	 file write `myfile' `"<li><a href="Files/`myvar'.html"><strong>`myvar'</strong>: `varlabel'</a></li>"' _n

	 if missing("`function'") {
		qui htmlpagevar `myvar'
	 }
	 if !missing("`function'") {
		qui htmlpagevar `myvar', function(`function') statname("`statname'")
	 }	
}

* End of list that can be operated on by search bar
file write `myfile' `"</ul>"' _n

* Save page
file close `myfile'

* Write out page that lists all variables (this doesn't inherit the sections,
* which I think is OK, but we could see if there's a way to do that)
	 if missing("`function'") {
		qui htmlpageallvars `varlist'
	 }
	 if !missing("`function'") {
		qui htmlpageallvars `varlist', function(`function') statname("`statname'")
	 }	

* Convert to html
whereis pandoc
local pandoc = r(pandoc)
shell "`pandoc'" "Codebook/`name'.md" -f markdown -t html -s -o "Codebook/`name'.html"
cap erase  "Codebook/`name'.md"

* Open page in browser
if c(os) == "MacOSX" view browse "file://`c(pwd)'/Codebook/`name'.html"
if c(os) != "MacOSX" view browse "`c(pwd)'/Codebook/`name'.html"


end

*******************************************************
* Function for writing out specific pages: htmlpagevar
*******************************************************
capture program drop htmlpagevar
program define htmlpagevar

syntax varname [, function(name) statname(string)]

* Create codebook folder at root of wd, if it doesn't already exist
cap mkdir Codebook
cap mkdir "Codebook/Files"

* Create markdown file
tempname myfile
file open `myfile' using "Codebook/Files/`varlist'.md", write replace

* copy in style sheet if it's not already in folder
cap confirm file "Codebook/Files/codebook_page.css"
if _rc copy "https://raw.githubusercontent.com/imaddowzimet/Misc/master/codebook_page.css" "Codebook/Files/codebook_page.css", replace

* link to style sheet
file write `myfile' `"<link rel="stylesheet" href="codebook_page.css">  "' _n

* TO DO: Would probably want to add some code here essentially testing what
* kind of function the user provided - if its only applicable to continous for
* example, and sets locals that can be used to make subsequent code more 
* flexible. 
* TO DO: Also, would probably be easy to allow a list of custom functions 
* instead, though this might be going too deep down the rabbit hole. 

* Store variable attributes
* Is it string?
local type: type `varlist'
if regexm("`type'", "str") {
    local string yes
}
else {
	local string no
}

* Is it categorical?
local categorical: char `varlist'[categorical]
local categorical `=lower("`categorical'")'

* Store value label, if it has one
local vallabel: value label `varlist'

* Store variable label, if it has one 
local varlabel : var label `varlist'

* Store variable universe
local myuniverse: char `varlist'[universe]

* For variables not explicitly string or categorical, try to guess whether
* the variable is categorical.                                                  // TO DO: Add an option about whether code should do this. 
if "`string'" == "no" & "`categorical'" != "yes" {
	
	   * Can it be compressed to an integer storage format (byte, int or long)?
	   tempvar clone 
	   clonevar `clone' = `varlist' 
	   compress `clone'
	   local type: type `clone'
	   if inlist("`type'", "byte", "long", "int" ) local integers yes
	   
	   * How many levels does it have (only relevant if above is true)?
	   if "`integers'" == "yes" {
		levelsof `varlist'
		local numvalues: word count `r(levels)'
       }
	   
	    * If it has a value label, then check whether it has <30 values; if it does
	    * it is probably categorical (or would be amenable to being shown as such)
	    if "`vallabel'"!="" &  	 "`integers'" == "yes" {  
	     if `numvalues'<30 local categorical yes
	    }	   
		
		* if it doesn't, then check whether it has <=5 values; if it does
	    * it is probably categorical (or would be amenable to being shown as such)
	    if "`vallabel'"=="" &  	 "`integers'" == "yes" {  
	     if `numvalues'<=5 local categorical yes
	    }	   	   
	   * To do: this code could probably be improved with real user testing
	   * Maybe looking to see what proportion of values have real value levels?
	
}

local myuniverse: char `varlist'[universe]

* Write out general header information
file write `myfile' "**Variable Name:** `varlist'  " _n
file write `myfile' "**Variable Label:** `varlabel'  " _n
file write `myfile' "**Variable Universe:** `myuniverse'  " _n
file write `myfile' "  " _n

* If the variable is string, then list all values
if "`string'" == "yes" {

	if missing("`function'") {
		file write `myfile' "| `varlist' |  N  |  " _n
		file write `myfile' "|:----------|----:|  " _n
    }
	if !missing("`function'") {
		file write `myfile' "| `varlist' |  N  | `statname'  |  " _n
		file write `myfile' "|:----------|----:|----:|  " _n
	}
	qui tab `varlist', matcell(values)
	qui levelsof `varlist'
	local levels r(levels)
	local levels `"`r(levels)'"'
	local upper: word count `levels'
	tokenize `"`levels'"'
	foreach mynum of numlist 1/`upper' {
		local myvalue = values[`mynum',1]
		local mylabel ``mynum''
		
		if missing("`function'") {
			file write `myfile' "| `mylabel'  | `myvalue'" _n
        }
		if !missing("`function'") {
		
			`function' `varlist' if `varlist' == "`mylabel'"
		     file write `myfile' "| `mylabel'  | `myvalue' | `r(stat)'" _n
		   
		}

	}

}

if "`string'" == "no" & "`categorical'" == "yes" {

	if missing("`function'") {
		file write `myfile' "| `varlist' | value | N  |  " _n
		file write `myfile' "|:----------|-----:|-----:|     " _n
	}
	if !missing("`function'") {
		file write `myfile' "| `varlist' | value | N  | `statname'  |  " _n
		file write `myfile' "|:----------|-----:|-----:|-----:|     " _n	
	}
	qui tab `varlist', matcell(values) missing
	qui levelsof `varlist', missing
	local levels r(levels)
	local levels `"`r(levels)'"'
	local upper: word count `levels'
	tokenize `"`levels'"'
	foreach mynum of numlist 1/`upper' {
		local myvalue = values[`mynum',1]
		if "`vallabel'" != "" local mylabel: label `vallabel' ``mynum''         // note the extra quotes for mynum, which call the tokenize locals, not mynum itself
		
		if missing("`function'") {
			file write `myfile' "| `mylabel' |  ``mynum'' | `myvalue'" _n
		}
	    if !missing("`function'") {
		    `function' `varlist' if `varlist' == ``mynum''
			file write `myfile' "| `mylabel' |  ``mynum'' | `myvalue' | `r(stat)'" _n

	    }		
		
	}

	* Note that when there are 0 observations for a category, it's omitted.
	* TO DO: think about whether this is desired behavior.

}
if "`string'" == "no" & "`categorical'" != "yes" {
	if missing("`function'") {
		file write `myfile' "| Obs | Mean| SD | Min | Max |   " _n
		file write `myfile' "|-----:|-----:|-----:|-----:|-----:|    " _n
	}
	if !missing("`function'") {
		file write `myfile' "| Obs | Mean| SD | Min | Max | `statname' |   " _n
		file write `myfile' "|-----:|-----:|-----:|-----:|-----:|-----:|    " _n
	}	
	
	
	qui summ `varlist'
	local obs  = r(N)
	local mean = round(`r(mean)', .001)                                         
	local mean: display `mean' %4.3f
	local sd   = round(`r(sd)'  , .001)
	local sd: display `sd' %4.3f
	local min  = round(`r(min)'  , .001)
	local min: display `min' %4.3f
	local max  = round(`r(max)'  , .001)
	local max: display `max' %4.3f
	if missing("`function'") {	
		file write `myfile' "| `obs' |  `mean' | `sd' | `min' | `max' |  " _n   
	}
	if !missing("`function'") {
		`function' `varlist'
		file write `myfile' "| `obs' |  `mean' | `sd' | `min' | `max' | `r(stat)' |    " _n   
	}
	file write `myfile' "  " _n
	file write `myfile' "  " _n
	set graphics off
	histogram `varlist', scheme(s1mono) 
	graph export "Codebook/Files/`varlist'.png", width(600) replace
	set graphics on
	file write `myfile' "![](`varlist'.png)  "
}
else {



}
file close `myfile'

* Erase html file if it already exists
cap erase  "Codebook/Files/`varlist'.html"

whereis pandoc
local pandoc = r(pandoc)
shell "`pandoc'" "Codebook/Files/`varlist'.md" -f markdown -t html -s -o "Codebook/Files/`varlist'.html"
cap erase  "Codebook/Files/`varlist'.md"


end

**************************************
** Program to write out all variables
**************************************
capture program drop htmlpageallvars
program define htmlpageallvars

syntax varlist [, function(name) statname(string)]

* Create markdown file
tempname myfile
file open `myfile' using "Codebook/Files/allvars.md", write replace

* link to style sheet
file write `myfile' `"<link rel="stylesheet" href="codebook_page.css">  "' _n

foreach myvar of varlist `varlist' {

* Store variable attributes
* Is it string?
local type: type `myvar'
if regexm("`type'", "str") {
    local string yes
}
else {
	local string no
}

* Is it categorical?
local categorical: char `myvar'[categorical]
local categorical `=lower("`categorical'")'

* Store value label, if it has one
local vallabel: value label `myvar'

local varlabel: variable label `myvar'


* For variables not explicitly string or categorical, try to guess whether
* the variable is categorical.                                                  // TO DO: Add an option about whether code should do this. 
if "`string'" == "no" & "`categorical'" != "yes" {
	
	   * Can it be compressed to an integer storage format (byte, int or long)?
	   tempvar clone 
	   clonevar `clone' = `myvar' 
	   compress `clone'
	   local type: type `clone'
	   if inlist("`type'", "byte", "long", "int" ) local integers yes
	   
	   * How many levels does it have (only relevant if above is true)?
	   if "`integers'" == "yes" {
		levelsof `myvar'
		local numvalues: word count `r(levels)'
       }
	   
	    * If it has a value label, then check whether it has <30 values; if it does
	    * it is probably categorical (or would be amenable to being shown as such)
	    if "`vallabel'"!="" &  	 "`integers'" == "yes" {  
	     if `numvalues'<30 local categorical yes
	    }	   
		
		* if it doesn't, then check whether it has <=5 values; if it does
	    * it is probably categorical (or would be amenable to being shown as such)
	    if "`vallabel'"=="" &  	 "`integers'" == "yes" {  
	     if `numvalues'<=5 local categorical yes
	    }	   	   
	   * To do: this code could probably be improved with real user testing
	   * Maybe looking to see what proportion of values have real value levels?
	
}

* Store variable universe
local myuniverse: char `myvar'[universe]

* Write out general header information
file write `myfile' "**Variable Name:** `myvar'  " _n
file write `myfile' "**Variable Label:** `varlabel'  " _n
file write `myfile' "**Variable Universe:** `myuniverse'  " _n
file write `myfile' "  " _n

* If the variable is string, then list all values
if "`string'" == "yes" {

	if missing("`function'") {
		file write `myfile' "| `myvar' |  N  |  " _n
		file write `myfile' "|:----------|----:|  " _n
    }
	if !missing("`function'") {
		file write `myfile' "| `myvar' |  N  | `statname'  |  " _n
		file write `myfile' "|:----------|----:|----:|  " _n
	}

	qui tab `myvar', matcell(values)
	qui levelsof `myvar'
	local levels r(levels)
	local levels `"`r(levels)'"'
	local upper: word count `levels'
	tokenize `"`levels'"'
	foreach mynum of numlist 1/`upper' {
		local myvalue = values[`mynum',1]
		local mylabel ``mynum''
		if missing("`function'") {
			file write `myfile' "| `mylabel'  | `myvalue'" _n
        }
		if !missing("`function'") {
		
			`function' `myvar' if `myvar' == "`mylabel'"
		     file write `myfile' "| `mylabel'  | `myvalue' | `r(stat)'" _n
		   
		}


	}

}

if "`string'" == "no" & "`categorical'" == "yes" {

	
	if missing("`function'") {
		file write `myfile' "| `myvar' | value | N  |  " _n
		file write `myfile' "|:----------|-----:|-----:|     " _n
	}
	if !missing("`function'") {
		file write `myfile' "| `myvar' | value | N  | `statname'  |  " _n
		file write `myfile' "|:----------|-----:|-----:|-----:|     " _n	
	}
	
	qui tab `myvar', matcell(values) missing
	qui levelsof `myvar', missing
	local levels r(levels)
	local levels `"`r(levels)'"'
	local upper: word count `levels'
	tokenize `"`levels'"'
	foreach mynum of numlist 1/`upper' {
		local myvalue = values[`mynum',1]
		
		if "`vallabel'" != "" local mylabel: label `vallabel' ``mynum''
		if missing("`function'") {
			file write `myfile' "| `mylabel' |  ``mynum'' | `myvalue'" _n
		}
	    if !missing("`function'") {
		    `function' `myvar' if `myvar' == ``mynum''
			file write `myfile' "| `mylabel' |  ``mynum'' | `myvalue' | `r(stat)'" _n

	    }	
	}

}
if "`string'" == "no" & "`categorical'" != "yes" {
	if missing("`function'") {
		file write `myfile' "| Obs | Mean| SD | Min | Max |   " _n
		file write `myfile' "|-----:|-----:|-----:|-----:|-----:|    " _n
	}
	if !missing("`function'") {
		file write `myfile' "| Obs | Mean| SD | Min | Max | `statname' |   " _n
		file write `myfile' "|-----:|-----:|-----:|-----:|-----:|-----:|    " _n
	}	
	
	qui summ `myvar'
	local obs  = r(N)
	local mean = round(`r(mean)', .001)                                         
	local mean: display `mean' %4.3f
	local sd   = round(`r(sd)'  , .001)
	local sd: display `sd' %4.3f
	local min  = round(`r(min)'  , .001)
	local min: display `min' %4.3f
	local max  = round(`r(max)'  , .001)
	local max: display `max' %4.3f
	if missing("`function'") {	
		file write `myfile' "| `obs' |  `mean' | `sd' | `min' | `max' |  " _n   
	}
	if !missing("`function'") {
		`function' `myvar'
		file write `myfile' "| `obs' |  `mean' | `sd' | `min' | `max' | `r(stat)' |    " _n   
	}
	file write `myfile' "  " _n
	file write `myfile' "  " _n
	file write `myfile' "![](`myvar'.png)  " _n
}
else {



}
file write `myfile' "<br> <br>   " _n
file write `myfile' "<hr/>  " _n

}

file close `myfile'

* Erase html file if it already exists
cap erase  "Codebook/Files/allvars.html"

whereis pandoc
local pandoc = r(pandoc)
shell "`pandoc'" "Codebook/Files/allvars.md" -f markdown -t html -s -o "Codebook/Files/allvars.html"
cap erase  "Codebook/Files/allvars.md"


end
