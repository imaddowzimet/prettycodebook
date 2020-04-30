{smcl}
{* *! version 1  8april2020}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "prettycodebookhelpfile##syntax"}{...}
{viewerjumpto "Description" "prettycodebookhelpfile##description"}{...}
{viewerjumpto "Options" "prettycodebookhelpfile##options"}{...}
{viewerjumpto "Remarks" "prettycodebookhelpfile##remarks"}{...}
{viewerjumpto "Examples" "prettycodebookhelpfile##examples"}{...}
{title:Title}

{phang}
{bf:prettycodebook} {hline 2} Generate interactive codebook (html)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:prettycodebook:}
{varlist}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt name:(name)}}set page name{p_end}
{synopt:{opt datasetname:(str)}}set codebook title{p_end}
{synopt:{opt function:(fn)}}additional information to display on individual variable pages{p_end}
{synopt:{opt statname:(str)}}title for additional information displayed on individual variable pages{p_end}
{synoptline}
{p2colreset}{...}



{marker description}{...}
{title:Description}

{pstd}
{cmd:prettycodebook} creates an interactive html codebook for the variables in {varlist}. The main page includes a header with the dataset title, a list of all variables included in the codebook (with links to individual pages for each variable), and a dynamic search bar.
Default features: {break}
. All variables: varname, var label, var universe (and any additional statistics specific in option {cmd:function()}{break}
. Categorical variables (incl. str): value labels, values, N {break}
. Continuous variables: N, mean, SD, min, max, and a histogram {break}
{cmd:prettycodebook} will determine what type each variable is and format the individual variable page accordingly (or can override by explicitly specifying categorical or continuous).
// SA NOTE: add info about how to override var type; add info about how to add sections using chars
// SA NOTE: look into updating prettycodebook.ado to use string instead of name (but would need to unstring later on in prettycodebook when it is used for a filepath)


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt name()} determines the title for the codebook's main page which lists all variables in the codebook (no default)

{phang}
{opt datasetname()} determines the title shown at the header of the codebook's main page (accepts a string, e.g. "Datasetname"; no default)

{phang}
{opt function()} calls other functions to display information on individual variable pages beyond the standard set included in {cmd:prettycodebook}. 
// SA NOTE: give more guidance on what the function would need to look like, test out with some functions (test with mean, see if it has to be user-written? Give an example of a custom-written function and put it in the example w auto dataset)

{phang}
{opt statname()} determines the title shown for the additional statistic included on the individual variable pages, as set using {cmd:function()} (accepts a string, e.g. "Newstat").





{marker examples}{...}
{title:Examples}

{phang}{cmd:. prettycodebook mpg weight, name(Index) datasetname("Auto")}{p_end}

