##------------------------------------------------------------
## Installation script for CSAMA 2025
##------------------------------------------------------------

##---------------------------
## Install BiocManager
##---------------------------
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("remotes", quietly = TRUE)) {
  suppressMessages(
    BiocManager::install("remotes", quiet = TRUE, update = FALSE, ask = FALSE)
  )
}
if (!requireNamespace("Biobase", quietly = TRUE)) {
  suppressMessages(
    BiocManager::install("Biobase", quiet = TRUE, update = FALSE, ask = FALSE)
  )
}

##-------------------------------------------
## installation function
##-------------------------------------------

installer_with_progress <- function(pkgs) {
  
  if(length(pkgs) == 0) { invisible(return(NULL)) }
  
  if(!requireNamespace("progress", quietly = TRUE)) {
    suppressMessages(
      BiocManager::install('progress', quiet = TRUE, update = FALSE, ask = FALSE)
    )
  }
  
  toInstall <- pkgs
  bp <- progress::progress_bar$new(total = length(toInstall),
                                   format = "Installed :current of :total (:percent ) - current package: :package",
                                   show_after = 0,
                                   clear = FALSE)
  
  length_prev <- length(toInstall)
  fail <- NULL
  while(length(toInstall)) {
    pkg <- toInstall[1]
    bp$tick(length_prev - length(toInstall),  tokens = list(package = pkg))
    length_prev <- length(toInstall)
    if(pkg %in% rownames(installed.packages())) {
      toInstall <- toInstall[-1]
    } else {
      tryCatch(
        suppressMessages( BiocManager::install(pkg, quiet = TRUE, update = FALSE, ask = FALSE,
                                               Ncpus = parallel::detectCores() ) ),
        error = function(e) { fail <<- c(fail, pkg) },
        warning = function(w) { fail <<- c(fail, pkg) },
        finally = toInstall <- toInstall[-1]
      )
    }
  }
  bp$tick(length_prev - length(toInstall),  tokens = list(package = "DONE!"))
  
  return(fail)
}

##-------------------------------------------
## System requirements
##-------------------------------------------
.required_R_version = c( "4.5.0", "4.5.1" )
.required_Bioc_version = "3.21"
.Bioc_devel_version = "3.22"
.required_rstudio_version = "2024.12.1"
.rstudio_url="https://posit.co/download/rstudio-desktop/"
options(warn = 1)
.yr = format(Sys.Date(), "%y")
## Check memory size
pattern = "[0-9]+"
min_mem = 4

mem =
  switch(.Platform$OS.type,         
         unix = 
           if (file.exists("/proc/meminfo")) {
             ## regular linux
             res = system('grep "^MemTotal" /proc/meminfo', intern=TRUE)
             as.numeric(regmatches(res, regexpr(pattern, res)))/10^6
           } else {
             if (file.exists("/usr/sbin/system_profiler")) {
               ## try MAC os
               res = system('/usr/sbin/system_profiler SPHardwareDataType | grep "Memory"', intern=TRUE)
               as.numeric(regmatches(res, regexpr(pattern, res)))
             } else NULL  
           },
         windows = 
           tryCatch({
             res = system("wmic ComputerSystem get TotalPhysicalMemory", ignore.stderr=TRUE, intern=TRUE)[2L]
             as.numeric(regmatches(res, regexpr(pattern, res)))/10^9
           }, error = function(e) NULL),
         NULL)

if (is.null(mem)) {
  warning(sprintf("Could not determine the size of your system memory. Please make sure that your machine has at least %dGB of RAM!", min_mem))
} else {
  mem = round(mem)
  if ( mem < min_mem ) stop(sprintf("Found %dGB of RAM. You need a machine with at least %dGB of RAM for the CSAMA course!", mem, min_mem))
  else message(sprintf("Found %dGB of RAM", mem))
}

## Check the R version
R_version = paste(R.version$major, R.version$minor, sep=".")
if( !(R_version %in% .required_R_version) )
  stop(sprintf("You are using a version of R different than the one required for CSAMA'%s, please install R-%s", .yr, .required_R_version[2]))

.baseurl = c( BiocManager::repositories() )

### Check Rstudio version
hasApistudio = suppressWarnings(require("rstudioapi", quietly=TRUE))
if( !hasApistudio ){
  BiocManager::install("rstudioapi", update=FALSE, siteRepos = .baseurl, quiet = TRUE, ask = FALSE)
  suppressWarnings(require("rstudioapi", quietly=TRUE))
}

.rstudioVersion = try( rstudioapi::versionInfo()$version, silent=TRUE )
if( inherits( .rstudioVersion, "try-error" ) ){
  .rstudioVersion = gsub("\n|Error : ", "", .rstudioVersion)
  rstudioError = sprintf("The following error was produced while checking your Rstudio version: \"%s\"\nPlease make sure that you are running this script from an Rstudio session. If you are doing so and the error persists, please contact the organisers of CSAMA'%s.\n", .rstudioVersion, .yr)
  stop( rstudioError )
}

if( !( .rstudioVersion >= .required_rstudio_version ) ){
  rstudioVersionError = sprintf("You are using a version of Rstudio different from the one required for CSAMA'%s, please install Rstudio v%s or higher.\nThe latest version of Rstudio can be found here: %s",
                                .yr, .required_rstudio_version, .rstudio_url)
  stop( rstudioVersionError )
}

if( BiocManager::version() != .required_Bioc_version )
  stop(sprintf("Please install Bioconductor %s\n", .required_Bioc_version))

## Get list of packages to install
## This can be created by running the following on the "REQUIRE_PACKAGES" file
## readLines("REQUIRED_PACKAGES") |> 
##   grep(pattern = "^[[:alpha:]]", value = TRUE) |> 
##   unique() |>
##.  stringr::str_trim() |>
##   stringr::str_c(collapse = "','") |> 
##   sprintf(fmt = "'%s'")
deps <- c(
  'hca','celldex','MASS','SummarizedExperiment','TENxPBMCData','SingleCellExperiment','scater','SingleR','devtools','DT','LoomExperiment','scuttle','rols','ontoProc','shiny','vjcitn/csamaDist','Spectra','mzR','QFeatures','MsCoreUtils','scp','scpdata','MsDataHub','rpx','tidyverse','factoextra','msdata','rhdf5','impute','ProtGenerics','PSMatch','pheatmap','limma','RforMassSpectrometry/SpectraVis','OSCA.intro','OSCA.basic','OSCA.advanced','OSCA.multisample','OSCA.workflows','ade4','airway','Biobase','dplyr','GGally','ggplot2','Hiiragi2013','phyloseq','ccb-hms/scDiagnostics','methods','isotree','RColorBrewer','ranger','Hotelling','rlang','AUCell','BiocStyle','knitr','Matrix','rmarkdown','scran','scRNAseq','testthat','tidyr','purrr','reshape2','stringr','terrainr','imagefx','dill/beyonce','EBImage','IHW','MsExperiment','MetaboCoreUtils','MetaboAnnotation','png','xcms','Spectra','DropletTestFiles','DropletUtils','EnsDb.Hsapiens.v86','scDblFinder','scry','NewWave','igraph','network','sna','intergraph','SpatialExperiment','STexampleData','ggspavis','nnSVG','BayesSpace','SPOTlight','ggcorrplot','scatterpie','arrow','SpatialFeatureExperiment','Voyager','SFEData','mikelove/airway2','tximeta','DESeq2','org.Hs.eg.db','vsn','ExploreModelMatrix','apeglm','iSEE','iSEEu','edgeR','rjson','AnnotationDbi','muscat','csoneson/ConfoundingExplorer','htmltools','tximport','iSEEde','quarto','patchwork','cowplot','AnnotationHub','BiocCheck','BiocFileCache','BiocManager','BiocParallel','biocthis','biomaRt','Biostrings','BSgenome','BSgenome.Hsapiens.UCSC.hg19','BSgenome.Hsapiens.UCSC.hg38','ensembldb','ExperimentHub','GenomicAlignments','GenomicRanges','GenomicFeatures','Gviz','Homo.sapiens','HubPub','hugene20sttranscriptcluster.db','IRanges','KEGGREST','Organism.dplyr','pwalign','readr','rtracklayer','Rsamtools','RNAseqData.HNRNPC.bam.chr14','tibble','TxDb.Hsapiens.UCSC.hg19.knownGene','TxDb.Hsapiens.UCSC.hg38.knownGene','VariantAnnotation','plyranges','tidybulk','tidySummarizedExperiment','nullranges','fluentGenomics','randomNames','GenomeInfoDb','ggridges','plotgardener','oct4','org.Mm.eg.db','ggrepel','fission','glmnet','lemur','muscData','MatrixGenerics','transformGamPoi','glmGamPoi','Seurat','irlba','uwot','harmony','scales', 'RforMassSpectrometry/Metabonaut', 'sparseMatrixStats', 'DelayedMatrixStats', 'remotes', 'MSnID', 'cleaver', 'PTMods'
)
deps <- data.frame(name = gsub(x = deps, "^.+/", ""),
                   source = deps, 
                   stringsAsFactors = FALSE)

## omit packages not supported on WIN and MAC
#type = getOption("pkgType")
#if ( type == "win.binary" || type == "mac.binary" ) {
#  deps = setdiff(deps, c('gmapR'))
#}
toInstall = deps[which( !deps$name %in% rownames(installed.packages())), "source"]

##---------------------------
## Additional installation commands
## If a lab requires something outside the norm, install it here
## e.g non-standard package versions
##---------------------------
# if((any(grepl("xcms", x = toInstall))) || (Biobase::package.version("xcms") < "3.99.0")) {
#   suppressMessages(
#     BiocManager::install("sneumann/xcms", ask = FALSE, quiet = TRUE, update = FALSE)
#   )
# }

## These two sections install some Mac package binaries directly. 
## At the time of CSAMA 2023 there were several packages that were "not available" via BiocManager::install()
## due to issues with dependencies in the build system, but the binaries had been created
## Installing these here saved work trying to get the compilers working for everyone to build from source.

# if("NewWave" %in% toInstall) {
#   if(Sys.info()["sysname"] == "Darwin") {
#     if(Sys.info()["machine"] == "x86_64") {
#       message("Installing NewWave x86_64")
#       install.packages("https://bioconductor.org/packages/release/bioc/bin/macosx/big-sur-x86_64/contrib/4.3/SharedObject_1.14.0.tgz", repos = NULL)
#       install.packages("https://bioconductor.org/packages/release/bioc/bin/macosx/big-sur-x86_64/contrib/4.3/NewWave_1.10.0.tgz", repos = NULL)
#     } else {
#       message("Installing NewWave arm64")
#       install.packages("https://bioconductor.org/packages/release/bioc/bin/macosx/big-sur-arm64/contrib/4.3/SharedObject_1.14.0.tgz", repos = NULL)
#       install.packages("https://bioconductor.org/packages/release/bioc/bin/macosx/big-sur-arm64/contrib/4.3/NewWave_1.10.0.tgz", repos = NULL)
#     }
#     toInstall <- setdiff(toInstall, "NewWave")
#   } else {
#     message("NewWave will be installed later. You can ignore this message.")
#   }
# }
# 
# if("densvis" %in% toInstall) {
#   if(Sys.info()["sysname"] == "Darwin") {
#     if(Sys.info()["machine"] == "x86_64") {
#       message("Installing densvis x86_64")
#       install.packages("https://bioconductor.org/packages/3.16/bioc/bin/macosx/contrib/4.2/densvis_1.8.3.tgz", repos = NULL)
#       toInstall <- setdiff(toInstall, "densvis")
#     } else {
#       message("Installing densvis binary not available for arm64")
#     }
#   } else {
#     message("NewWave will be installed later. You can ignore this message.")
#   }
# }


##---------------------------
## Install the required packages
##---------------------------
# do not compile from sources
options(install.packages.compile.from.source = "never")
if(.Platform$OS.type == "windows" || Sys.info()["sysname"] == "Darwin") {
  BiocManager::install(toInstall, ask = FALSE, quiet = TRUE, update = FALSE)
} else {
  fail <- installer_with_progress(toInstall)
}

##---------------------------
## Download required datasets
##---------------------------

DropletTestFiles::getTestFile("tenx-2.1.0-pbmc4k/1.0.0/raw.tar.gz")
celldex::MonacoImmuneData()
STexampleData::Visium_humanDLPFC()
scRNAseq::fetchDataset("zhong-prefrontal-2018", version = "2023-12-22")
SFEData::HeNSCLCData()

##-------------------------
## Feedback on installation
##---------------------------
if(all( deps$name %in% rownames(installed.packages()) )) {
  cat(sprintf("\nCongratulations! All packages were installed successfully :)\nWe are looking forward to seeing you in Brixen!\n\n"))
} else {
  notinstalled <- deps[which( !deps$name %in% rownames(installed.packages()) ), ]
  
  if( .Platform$pkgType == "win.binary" & 'Rsubread' %in% notinstalled ){
    cat("The windows binaries for the package 'Rsubread' are not available. However, this package is not 100% necessary for the practicals. If this is the only package
    that was not installed, there is no reason to worry. \n")
  }
  
  cat(sprintf("\nThe following package%s not installed:\n\n%s\n\n", if (length(notinstalled)<=1) " was" else "s were", paste( notinstalled$name, collapse="\n" )))
  
  if( .Platform$pkgType != "source" ){
    message("Please try re-running the script to see whether the problem persists.")
  } else {
    install_command <- paste0("BiocManager::install(c('", paste(notinstalled$source, collapse = "', '"), "'))")
    message("Please try running the following command to attempt installation again:\n\n",
            install_command, "\n\n")
  }
  
  message("If you need help with troubleshooting, please contact the course organisers, or the CSAMA'25 Slack channel (https://CSAMA2025.slack.com).")
  
  if( .Platform$pkgType == "source" ){
    message("Some of the packages (e.g. 'Cairo', 'mzR', rgl', 'RCurl', 'tiff', 'XML') that failed to install may require additional system libraries.*",
            "Please check the documentation of these packages for unsatisfied dependencies.\n",
            "A list of required libraries for Ubuntu can be found at https://csama2025.bioconductor.eu/installation_script/linux_libraries.sh \n\n")
  }
}
