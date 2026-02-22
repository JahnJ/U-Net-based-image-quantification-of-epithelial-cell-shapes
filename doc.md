::::: titlepage
:::: center
::: picture
(12,4) (0,1.8)

**U-Net based ZO-1 image processing for advanced immunofluorescence
analysis - end user documentation**
:::

Revision 2.0 11.03.2025  Author: Johannes Jahn
johannes.jahn@uniklinik-freiburg.de
::::
:::::

# Introduction {#cha:introduction}

Based on the idea to compute unbiased measurements for
immunofluorescence images a multi-step image processing pipeline was
developed. This system replaced the error-prone and time-consuming
analysis by hand that couldn't provide numerical values for the image
characteristics. The methods can be used to evaluate immunofluorescence
images stained with antibodies against ZO-1. This documentation should
serve as a step-by-step instruction to process and analyze own
image-datasets. For more detailed information of the methods and the
theoretical background please have a look publication and the source
code.

To better understand the whole system the following text gives brief
explanations about the individual processing steps. First, the image
capturing takes place. The previously stained microscope preparations
are captured and saved as individual files. The second step is the image
segmentation using a U-Net deep learning network. This step is executed
in ImageJ/Fiji and detects the relevant image components. The third and
fourth step are run in Mathematica. It performs the modeling algorithms
and the measuring of the image components. Afterwards, the images can be
divided into individual groups (e.g. genotype or different treatment)
and the gathered data is statistically quantified and visualized.

![Processing steps of the whole
workflow](media/workflow.png){#fig:workflow}

# Preparation {#cha:preparation}

All necessary files, portable software and documentation can be found on
github:

They should be copied to the storage of each local machine to avoid
problems. Please read the whole documentation carefully.

# Image acquisition and preprocessing {#cha:image-acquisition}

This chapter covers all relevant information for image capturing with
immunofluorescence microscopes and the necessary file naming and folder
structure for the automatic image pipeline.

## Capturing process {#sec:capturing-process}

For the published work the images were captured with a Carl Zeiss Axio
Observer Z.1 microscope. To avoid problems with later processing steps
preferably use similar settings:

- objective: Objektiv i Plan-Apochromat 63x/1.4 Oil DIC M27

- optovar: 1x Tubelens

- exposure time: manually set and consistent for each dataset

- file format: Carl Zeiss Image (\*.czi)

This will result in following image dimensions:

- image size (pixel): 1388 x 1040

- image size (scaled): 142.10µm x 106,48µm

- scaling: 0.1024µm/pixel

Preparations with multiple staining's and different wavelengths can be
captured in one step and saved to one file; the wavelength channels can
later be separated from each other. If necessary, different focus plains
can be captured and saved to individual files. For file naming please
see section [3.2](#sec:naming){reference-type="ref"
reference="sec:naming"}.

Based on the preparation condition the image quality may vary and affect
the processing. Especially some of the ZO-1 antibodies produce weak
stainings and image capturing can be quite a challenge. The best
possible preparations and image sections should be saved. However,
cherry picking should be avoided. The strength of the automatic image
processing lies in the large number of images and big datasets. The user
introduced bias should be as low as possible. Also, the focus point
should be exact on the relevant structures. Out of focus image parts
might be ignored in the automatic processing or lead to incorrect
results.

If you use other microscope vendors the file format may change. Larger
adaptions to the ImageJ script and the U-Net processing may be
necessary.

### Special Case: stitched images {#ssec:stitched}

Stitched images can be captured. They consist of multiple contiguous
image tiles. This increases the amount of data in a single image and
reduces the selection bias. The number of image tiles can usually be
selected in the microscope software and is automatically captured.
Stitched images in 3x3 configuration appeared to show the best results
regarding capture time, processing speed and information gain. Other
configurations up 10x10 are possible without difficulty.

The remaining microscope configurations, as described above, can stay
the same. The image size varies depending on the number of tiles. The
scaling 0.102µm/pixel should stay the same or will otherwise be rescaled
be the U-Net.

## File naming and folder structure {#sec:naming}

Most of the scripts and software expect an exact folder name and will
interrupt, if something variate. Therefore, it is extremely important to
use a consistent naming scheme. The following rules should be convenient
to organize the files and are essential for the whole processing.

### Folder names and structure {#ssec:folder-naming}

This is an example how the folder-tree should look like:

<figure data-latex-placement="H">

<figcaption>Foldertree</figcaption>
</figure>

All Folders marked in red need to have the exact name, otherwise the
scripts won´t work. Other folders can be individually changed by the
user. Long folder names can be a problem one some operating system and
should be avoided!

For each experiment, dataset or staining an own folder can be created.
These folders can begin with the date in the style YYYYMMDD for easy
identification and sorting. Additional information can be added to this
folder name. For stitched images the suffix '\_stitched' needs to be
added to the folder name (e.g. dapi_stitched). The file names can be
individually chosen.

Additional files (for example: text- or excel-files) can be stored in
the folders. They are ignored during processing.

# U-Net segmentation {#cha:unet}

This chapter lists all steps necessary to use the U-Net segmentation via
ImageJ. To avoid the multiple pitfalls that might interrupt the
processing the following chapter should be studied very carefully.

## Initial Preparation {#sec:unet-preparation}

The technical implementation of the U-Net deep learning requires two
components: A Server running the necessary deep learning framework and
performing the segmentation step of the images. Furthermore, another
computer running ImageJ as a client software to communicate with the
server and sending the image files. ImageJ can be run on nearly any
computer.

## U-Net Server {#sec:unet-server}

The details on setting up the U-Net server are slightly complicated and
will not be discussed at this point. Please have a look at
[@{.falkRepo}] and [@Falk.2019].

## ImageJ/Fiji {#sec:imagej}

ImageJ is a widely used software for medical and scientific image
editing and analysis. Fiji is an adapted version of ImageJ with an
extended set of plugins. For the U-Net client implementation Fiji with
the U-Net plugin is used in the following version, updated versions of
ImageJ should in theory work without problems.

- Fiji ImageJ 1.53b + Java 1.8.0_212

- U-Net Plugin v20190926220201

- HDF5_Vibez Plugin v20150214134118

## First use on new Client machine {#sec:first-use}

On every new client computer/user account a few basic settings need to
be configured when using ImageJ for the first time.

### Delete ImageJ configuration {#ssec:imagej-config}

To avoid problems with older ImageJ versions and settings the
configuration file should be deleted.

1.  On windows machines move to following folder:
    C:/Users/Username/.imagej/

2.  Delete the 'IJ_Prefs.txt' file

### Bio-Formats configuration {#ssec:bioformats}

The Bio-Formats plugin handles the loading and pre-processing of
microscope image files. For the Zeiss 'czi-files' a few specific
adjustments need to be made for automatic processing.

1.  Open ImageJ

2.  Click on 'File' 'Open' and open a random czi-file. This should open
    the import options dialogue window

3.  Select the options as shown in fig.
    [4.1](#fig:bioformats-1){reference-type="ref"
    reference="fig:bioformats-1"}. Especially 'Split channels' is
    important

4.  Click ok and close the opened image

5.  Click on 'Plugins' 'Bio-Formats' 'Bio-Formats Plugins Configuration'

6.  Click on the 'Formats' tab and select 'Zeiss CZI' in the list

7.  Check all boxes as shown in fig.
    [4.2](#fig:bioformats-2){reference-type="ref"
    reference="fig:bioformats-2"}. This will hide the import options
    dialogue window when opening a file

![Bio-Formats import options](media/bioformats-1.png){#fig:bioformats-1
width="80%"}

![Bio-Formats Plugins
configuration](media/bioformats-2.png){#fig:bioformats-2 width="80%"}

### U-Net plugins settings {#ssec:unet-plugin-settings}

The U-Net plugin handles the connection to the remote U-Net server and
the transfer of the image files opened for segmentation. Before using
the script for automatic processing, the plugin needs to be run by hand
for one time to write relevant options in the configuration file. These
steps can also be used if you want to segment a single image e.g. for
fast analysis or to monitor the quality of the trained model.

1.  Open ImageJ

2.  Click on 'File' 'Open' and open a random czi-file.

3.  Click on 'Plugins' 'U-Net' 'Segment Current Image (Hyperstack)'

4.  Enter the fields as shown in fig.
    [4.3](#fig:unet-plugin){reference-type="ref"
    reference="fig:unet-plugin"}. The model-file (filename ends with
    \*.modeldef.h5) and RSA-keyfile should be stored on your local
    machine. The file path can be selected with the folder button.

5.  Click and wait until segmentation is finished (will open a new
    windows with the segmented image)

6.  When executing the plugin for the first time a few dialogs need to
    be accepted by clicking on 'yes'. These dialogs are shown in fig.
    [4.4](#fig:ssh-messages){reference-type="ref"
    reference="fig:ssh-messages"}.

7.  Close all images

![U-Net segmentation plugin with filled in
settings](media/unet-plugin.png){#fig:unet-plugin width="70%"}

![Dialogs to confirm when starting the U-Net segmentation for the first
time](media/ssh-messages.png){#fig:ssh-messages width="60%"}

### Adapt Script to new machine {#ssec:adapt-script}

The provided script for ImageJ combines all functions from image
loading, U-Net segmentation and file saving. It is the essential part in
the automated workflow. It contains a few basic options, such as file
paths, that need to be manually set for each machine.

1.  Open ImageJ

2.  Click on 'File' 'Open' and open the provided file
    'U-Net-Processing-Library_v2.ijm' (or newer version number).
    Alternatively, you can drag and drop the file into ImageJ

3.  This opens a new window showing the source code of the script (see
    fig. [4.5](#fig:image-script){reference-type="ref"
    reference="fig:image-script"})

4.  Change the server settings and adapt the file paths of the RSA- and
    model-files to the paths of your local machine (line 19-30, see fig.
    [4.5](#fig:image-script){reference-type="ref"
    reference="fig:image-script"} - line number might change in newer
    versions of the script)

5.  The processing step size (line 37-38) can be reduced when the
    computer has a small amount of memory

6.  Click on 'File' 'Save as...' and save the changed file to your
    machine

![U-Net processing script opened in ImageJ showing parts of the source
code](media/unet-script.png){#fig:image-script width="100%"}

## Automatic image segmentation via U-Net {#sec:image-segmentation}

To minimize the necessary user interaction and to provide an easy
application a script for ImageJ was developed. As described above it
combines and automates all essential steps in the U-Net segmentation
workflow. The execution of the script is fairly easy and only needs a
few input settings by the user.

### Start the script {#ssec:start-script}

Now the actual U-Net processing can start. After setting up the
parameters the script will process the input folder with all subfolders
completely automatic. Depending on image size, number of files and
network speed this might take a while (usually 15min for 200 single
images, stitched images take longer). When finished a dialog box is
displayed.

1.  Open ImageJ

2.  Click on 'File' 'Open' and open the provided file
    'U-Net-Processing-Library_v2.ijm'. Alternatively, you can drag and
    drop the file into ImageJ

3.  This opens a new window showing the source code of the script (fig.
    [4.5](#fig:image-script){reference-type="ref"
    reference="fig:image-script"}). Click on 'Run' in the bottom left
    part of the window

4.  Select the settings you want to use to process the folder and press
    'OK' (see fig. [4.6](#fig:script-filenumber){reference-type="ref"
    reference="fig:script-filenumber"}) (Description of the settings is
    written in section
    [4.5.2](#ssec:script-settings){reference-type="ref"
    reference="ssec:script-settings"})

5.  Select the folder you want to process in the opened dialogue window
    (Please refer to the folder guidelines section in
    [3.2.1](#ssec:folder-naming){reference-type="ref"
    reference="ssec:folder-naming"})

6.  The next dialog window reports the number of files found in the
    selected folder. Press on 'OK' to start the processing (fig.
    [4.6](#fig:script-filenumber){reference-type="ref"
    reference="fig:script-filenumber"})

7.  Wait till the whole process is finished and it will show the final
    dialog box. You can see the current processing steps in the bottom
    part of the ImageJ main window. Depending on the server-connection
    and the amount of images it may take a while

![Dialog window showing the number of detected files before starting the
U-Net
processing](media/unet-script-filenumber.png){#fig:script-filenumber
width="50%"}

### Script settings {#ssec:script-settings}

The script can handle various settings for different experiments and
image formats. At the beginning of the script-run a dialog window let
the user select the desired settings for the specific dataset (see fig.
[4.7](#fig:script-settings-window){reference-type="ref"
reference="fig:script-settings-window"}). Below the details for each
selectable option are shown:

- Image-Type: The dropdown list lets the user select the antibody
  staining for the images. For multiple fluorescence channels in one
  image the script needs to be run multiple times.

- Channel: For images with multiple fluorescence channels the number of
  the channel matching the selected antibody staining/image type is
  specified. The channel numbering starts with the '0'. For example:
  image file with two channels: DAPI: channel 0; ZO-1: channel 1

- GFP-Channel: For images with GFP fluorescence the number of the
  GFP-channel is specified. It only needs to be inputted if the 'Save
  GFP-Channel'-option below is checked.

- Stitched: If checked the script will search for stitched images and
  apply necessary preprocessing options.

- Save GFP-Channel: If checked the script will process the specified
  GPF-channel and save the channel in a separate file. For some
  experiments this can be used to get additional information about
  different genotypes in one image.

- Save scores: If checked the script saves the score image generated by
  the U-Net plugin. It can be used to validate the segmentation output.
  For usual analysis this option is not needed.

![Script dialog window to select the settings for automatic
processing](media/unet-script-settings.png){#fig:script-settings-window
width="60%"}

### Processing folders and validation overlays {#ssec:script-folders}

Inside each image folder the script will create a set of subfolders to
store the processed data. These will also be used for further processing
steps in Mathematica. The filename of the newly created files mostly
consists of the original image-filename with an added suffix. Hence, the
original filename should be carefully composed. Following files are
stored inside the created folders:

- gfp: this folder stores the processed GFP image.

- processing: Used by Mathematica (see chapter
  [5](#cha:mathematica-part1){reference-type="ref"
  reference="cha:mathematica-part1"} and
  [6](#cha:mathematica-part2){reference-type="ref"
  reference="cha:mathematica-part2"}) to save the processed image

- processing_overlay: Used by Mathematica to save additional images for
  validation purposes

- processing_xlsx: Used by Mathematica to save the computed values in an
  excel file (\*.xlsx)

- segmented_overlay: Stores an overlay image, that can be used validate
  the U-Net output. It overlays the original image (s/w) with the U-Net
  segmentation (green). Example shown in fig.
  [4.8](#fig:unet-output){reference-type="ref"
  reference="fig:unet-output"}

- zo1_seg: This folder contains the segmentation images generated by the
  U-Net. These are 16-bit tiff-files. Hence, most image viewers
  (Windows/Photoshop) have problems viewing these files. ImageJ can open
  these images without trouble. Example shown in fig.
  [4.8](#fig:unet-output){reference-type="ref"
  reference="fig:unet-output"}

- zo1_seg_score: This folder stores the additional image file, that
  shows the segmentation scores. Please use ImageJ to open these files.
  Example shown in fig. [4.8](#fig:unet-output){reference-type="ref"
  reference="fig:unet-output"}

![A: validation overlay showing the raw image and the U-Net segmentation
in green; B: U-Net segmentation, in this case showing the detected cell
borders; C: This image shows the scores computed by the U-Net network -
based on these values the segmentation is
generated.](media/unet-output.png){#fig:unet-output}

## Common Errors {#sec:unet-errors}

Unfortunately, the whole process is not completely error-free. Most
problems occur with the server connection to the U-Net server or missing
files. The most common errors and their solution are described below.
For other errors restarting ImageJ or the operation system might help.
Otherwise, a fresh installation following all steps of this
documentation can help.

##### Error Message ImageJ:

In rar cases opening ImageJ or the U-Net processing script might cause
an error. This is shown in an additional console window (example shown
in fig. [4.9](#fig:imagej-error-1){reference-type="ref"
reference="fig:imagej-error-1"}). Restarting ImageJ and/or the operating
system should fix this problem.

![ImageJ error message](media/error1.png){#fig:imagej-error-1
width="70%"}

##### No files are found or the number doesn't match the input:

The script will display an error message if no files for processing are
found. In this case check if the right input folder was selected, if the
subfolders match the required name scheme (see
[3.2.1](#ssec:folder-naming){reference-type="ref"
reference="ssec:folder-naming"}) and if all microscopic image files are
correctly placed. Rerun the script after resolving these problems. If
the number of files doesn't match the expected quantity, likely a typo
or other problems with the folder name might cause image files not to be
found.

![Error message when no files are
found](media/error-2.png){#fig:imagej-error-2 width="100%"}

##### SSH connection error:

If the U-Net server cannot be reached an error is displayed (see fig.
[4.11](#fig:imagej-error-3){reference-type="ref"
reference="fig:imagej-error-3"}). After this initial message multiple
error messages are displayed which can be ignored. To fix this error
double check the network settings. Sometimes ImageJ needs to be
restarted, after setting the connection.

![Error message when the U-Net server can not be
reached](media/error-3.png){#fig:imagej-error-3 width="40%"}

##### Modell/RSA Key not found:

The script will display an error message, if essential files for the
processing are not found
([4.12](#fig:imagej-error-4){reference-type="ref"
reference="fig:imagej-error-4"}). The file paths need to be checked (see
section [4.4.4](#ssec:adapt-script){reference-type="ref"
reference="ssec:adapt-script"}) and corrected.

![Error message when crucial files are not
found](media/error-4.png){#fig:imagej-error-4 width="100%"}

##### Weight file upload dialog:

This window is shown if the weight file (part of the U-Net model) is not
found on the server (fig.
[4.13](#fig:imagej-error-7){reference-type="ref"
reference="fig:imagej-error-7"}). Click on 'Abbrechen' or 'cancel' and
check the file paths (see section
[4.4.4](#ssec:adapt-script){reference-type="ref"
reference="ssec:adapt-script"}).

![Upload dialog when essential parts of the U-Net model are not found on
the server or the given file path is
wrong](media/error-7.png){#fig:imagej-error-7 width="70%"}

##### Other errors:

Other errors can occur when the depending files on the U-Net server are
moved or changed (see fig.
[4.14](#fig:imagej-error-5){reference-type="ref"
reference="fig:imagej-error-5"}). Make sure the file paths stated in the
script are correct and contact the U-Net server administrator for
persisting errors . Another rare error is displayed when any step in the
script might cause problems (shown in
[4.15](#fig:imagej-error-6){reference-type="ref"
reference="fig:imagej-error-6"}). In this case restart ImageJ and rerun
the script. Check your input files and microscope settings.

![U-Net error message](media/error-5.png){#fig:imagej-error-5
width="50%"}

![Script error showing difficulties in automatic
processing](media/error-6.png){#fig:imagej-error-6 width="100%"}

# Mathematica Scripts Part 1 - Detection {#cha:mathematica-part1}

This chapter covers the second step in the automatic processing pipeline
which applies the modeling functions and algorithms at the previously
segmented images.

## Initial Preparation {#sec:mathematica-preparation}

After finishing the U-Net processing in ImageJ, later steps are executed
in Mathematica. Mathematica is a software package developed by Wolfram
Research and provides a programming language with lots of advanced image
processing and visualization methods. An activated Mathematica
installation on the local machine is needed to run the analysis. All
scripts containing the processing functions were developed and
extensively tested on Mathematica 12. Newer versions should also work.
For details on purchasing and installing Mathematica please have a look
at the website https://www.wolfram.com/mathematica/.

## The scripts {#sec:math-step1-scripts}

Source code in Mathematica is organized in so called 'Notebooks'. An own
script/notebook was developed, which contains all the functions and
methods to process the images. You don't need to know the technical
details and using the scripts/notebooks is done in a few easy steps
described below ([5.4](#sec:math-step1-run){reference-type="ref"
reference="sec:math-step1-run"}). For technical insights please have a
look at the whole commented source code listed under 'Initialising' in
the notebook itself.

Following core features are implemented in the scripts: Detect the cells
based on the tight junction segmentation. Apply a smooth model and
calculate the model parameter R-index showing differences in tight
junction structure (riffle vs. smooth). For special experiments the
cells can be fragmented into multiple cell border segments and the
orientation of these segments based on the neighbor cell genotype is
calculated.\
The name 'Detection' is referring to the first step in Mathematica,
which applies the developed modeling and analyzing algorithms to the
segmented images generated by the U-Net.

Every notebook is structured in a similar way. When opening the file it
shows the different parts in a plain overview (see fig.
[5.1](#fig:mathematica-script-screen){reference-type="ref"
reference="fig:mathematica-script-screen"}). The header shows the name
of the script and basic information like date of last changes. The
'Change log' and 'Initializing' part should be collapsed. When opening
it with the arrow symbol it shows details about the latest applied
changed or the whole annotated source code with all necessary functions.
The 'Run' part contains the relevant variables, that are definable by
the user itself, and the functions to run the script divided in one or
multiple code blocks.

![Screen when opening a Mathematica notebook, in this case for the ZO-1
detection script. The brackets on the right side show the separation of
the code
blocks.](media/mathematica-detection-script-2.png){#fig:mathematica-script-screen
width="100%"}

## Placing the scripts {#sec:math-step1-placing}

Each script will look for the specific file and folder structure (see
section [3.2.1](#ssec:folder-naming){reference-type="ref"
reference="ssec:folder-naming"}). After finishing the U-Net processing
the Mathematica script needs to be placed in the parent folder, as shown
in the folder tree at [3.2.1](#ssec:folder-naming){reference-type="ref"
reference="ssec:folder-naming"}. No files or folders need to be changed
between between these processing steps. The script will automatically
find the right folders containing the segmented images. Multiple
subfolders (e.g. for different experiment dates) are automatically
detected and processed in one run of the script. Placing the script file
at another folder might lead to wrong results picking not all or too
many files. Please be sure that only the files/folders you want to
process are in the subfolders at the script location.

## Run the scripts {#sec:math-step1-run}

After all preparations the scripts can be run. Depending on image size,
number of files and the scripts settings it might take some time and can
run hours until finished. A progress bar gives a visual output about the
current status. Each code block needs to be run separately. The single
code blocks a separated by brackets shown on the right side of the
notebook (see fig.
[5.1](#fig:mathematica-script-screen){reference-type="ref"
reference="fig:mathematica-script-screen"}).

1.  Open the script placed in the parent folder.

2.  Scroll down to the 'Run' section.

3.  Right click on the first code block (preferably directly on the text
    to select the correct block) and click onto 'Evaluate Cell' in the
    dropdown menu. The first block will close all existing computation
    kernels which will help avoid side effects with previously run
    scripts.

4.  When asking 'Do you want to automatically evaluate all the
    initialization cells in the notebook' click on 'Yes'.

5.  Wait until execution is finished -- the code block brackets on the
    right side stays bold during the execution.

6.  Adapt the settings in the second block if required (see
    [5.5](#sec:math-step1-settings){reference-type="ref"
    reference="sec:math-step1-settings"} for details).

7.  Evaluate the second block as described in Step 3 and 5.

8.  Evaluate the third block as described in Step 3 and 5. This should
    display a text with the number of files found for processing.
    Recheck file structure if numbers don't match the expectations.

9.  Evaluate the fourth block as described in Step 3 and 5. This block
    starts the actual image processing and may take some time until
    finished.

10. Close the script when all code blocks ran successfully. The script
    file doesn't need to be saved.

## Script settings {#sec:math-step1-settings}

The second code block in the 'Run'-section ('Define settings') of each
script lets the user define parameters of the processing. Most of the
time the default settings are suitable and don't need to be changed. The
following table shows the different variables with a short explanation.

::: center
  parameter name   default setting      explanation
  ---------------- -------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  parameter name   default setting      explanation
                                        
  segFolderZo1     '\\\\zo1_seg \\\\'   See explanation above: 'segFolderDapi'.
  gfp              False                This setting will enable an additional analysis mode. It can only be used if for each image the GFP-immunofluorescence channel is also acquired and saved in an additional file (can be done with the ImageJ script). This can divide the cell population into different groups (e.g. wild type and knock-out). To enable set the parameter to True'.
  gfpFolder        '\\\\gfp \\\\'       Defines the folder that stores the additional GFP-images. Will only be used if GFP-processing is requested (see above). The folder is usually created by the ImageJ-script and the default setting doesn't need to be changed.
  singleBranch     False                This setting will enable an additional analysis mode that divides each detected cell object into subsegments of the cell wall. Measurements are acquired for each subsegment and not the whole cell. In most cases this step is combined with the GFP-analysis and specific cell segments (e.g. between wild type and knock-out cells) can be examined. To enable set the parameter to 'True'.
  formAnalysis     False                The form analysis function will create a matrix file overlaying all detected cells. This can be used for advanced evaluation of morphogenesis. In most cases this setting is experimental and can be excluded, otherwise the setting can be changed to 'True'.
  pixelSize        0.1024               See explanation above: 'pixelSize'
:::

## Interpret output {#sec:math-step1-output}

The detection scripts create multiple files containing the measurements,
images showing the modelling effects and images that can be used to
validate the output or the processing in general. The following
subsection lists all created export files with a short description. The
star '\*' in the filename is a place holder for the original file name
of each immunofluorescence image file.

### ZO-1 {#ssec:math-step1-zo1-output}

All files created with the ZO-1-Detection script:

::: center
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --
  **zo1/processing/\*\_original.jpg:** The detected, coloured cells are shown with the calculated R-Index displayed in the middle of each cell.                                                                                                                                                                                                                                                        
  **zo1/processing/\*\_round.jpg:** These images show the cell objects after applying the smooth model.                                                                                                                                                                                                                                                                                                
  **zo1/processing/\*\_form_analysis \_fullcell.jpg:** This file is only created if the form analysis function is used. It will overlay all detected cell objects with their centre points and create a head map showing overlapping parts (violet: only a few cells overlap at this pixel, red: most cells overlap at this pixel) It´s a simple way to visualise differences in morphogenesis.        
  **zo1/processing_overlay/\*\_overlay_riffle \_round.jpg:** This is a validation image, that overlays the U-Net output with the smoothed cell borders that are created in the modelling process. It can be used to check to quality of the modelling.                                                                                                                                                 
  **zo1/processing_overlay/\*\_gfp_overlay.jpg:** This file is only created if the GFP-processing is requested. This image overlays the GFP-signal (in red) with the detected cells. GFP labelled cells and irregularities in the GFP-signal can be easily spotted.                                                                                                                                    
  **zo1/processing_overlay/\*\_single \_branch.jpg:** Only created when the single branch analysis is used. This image shows the detected cells and displays the R-Index for each segment of the cell border. Can be used to evaluate the modelling of the branch analysis. When using additional GFP-information (as shown in the 'gfp_overlay'-file) the differences of the subgroups can be seen.   
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --
:::

#### Excel output file {#ssaec:math-step1-zo1-excel1}

##### zo1/processing_xlsx/\*\_zo1.xlsx:

This is the essential file containing all measurements. It's the basis
for later visualisation and data processing. See figure
[5.2](#fig:zo1-excel-1){reference-type="ref"
reference="fig:zo1-excel-1"} for an example of the file structure. Row 3
shows the mean values of all single cell objects (that are listed in the
second part of the file) and therefore provide key values for the whole
image. Following parameter are acquired and shown in the columns (less
important parameters are greyed out):

![Example structure of the excel file containing all ZO-1 related
measurements](media/zo1-excel.png){#fig:zo1-excel-1 width="100%"}

::: center
  parameter                unit                               description
  ------------------------ ---------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  parameter                unit                               description
  cell number              \-                                 Individual number of each cell
  area                     µm²                                approximate area, where each pixel area is weighted by its neighborhood configuration[@reference.wolfram_2021_componentmeasurements]
  equivalentDiskRadius     µm                                 radius of a disk that has the same area[@reference.wolfram_2021_componentmeasurements]
  areaRadiusCoverage       \-                                 fraction of pixels within the equivalent disk radius[@reference.wolfram_2021_componentmeasurements]
  authalicRadius           µm                                 radius of a circle with the same polygonal perimeter length[@reference.wolfram_2021_componentmeasurements]
  outerPerimeterCount      µm                                 number of elements adjacent to the component[@reference.wolfram_2021_componentmeasurements]
  perimeterLength          µm                                 total length of outer pixel sides[@reference.wolfram_2021_componentmeasurements]
  meanCentroidDistance     µm                                 mean distance of all elements from the centroid[@reference.wolfram_2021_componentmeasurements]
  maxCentroidDistance      µm                                 maximum distance of all elements from the centroid[@reference.wolfram_2021_componentmeasurements]
  minCentroidDistance      µm                                 minimum distance of all elements from the centroid[@reference.wolfram_2021_componentmeasurements]
  filledCircularity        \-                                 circularity after filling holes[@reference.wolfram_2021_componentmeasurements]. This parameter can be used as a marker for cell morphogenesis. Round cell objects have a circularity close to '1', whereas irregular shaped cells have smaller values.
  rectangularity           \-                                 fraction of pixels within the minimal bounding box[@reference.wolfram_2021_componentmeasurements]
  medoid                   {pixel-position, pixel-position}   coordinate of the closest element to the centroid[@reference.wolfram_2021_componentmeasurements]
  polygonalLength          µm                                 total length of the polygon formed by the centers of the perimeter elements[@reference.wolfram_2021_componentmeasurements]. Most accurate parameter for the cell circumference and one of the key parameters for the R-Index model.
  GFP                      True/False                         Shows the GFP-status of the cells, if an additional GFP-file is available and the processing option is used. Otherwise, the table shows 'no GFP data'.
  polygonalLength smooth   µm                                 Polygonal length for the round cell objects (see above at polygonalLength)
  R-Index                  \-                                 The key modelling parameter showing the differences in cell border homogeneity and riffle strength.
  single branch R-Index    \-                                 List of R-Indices for each subsegment of the cell border if the single branch processing is used. Otherwise, this field is left empty.
:::

#### Excel output file branches {#ssaec:math-step1-zo1-excel2}

##### zo1/processing_xlsx/\*\_branches.xlsx:

This excel file is only created if the single branch processing is used.
Like the '\*\_zo1.xlsx'-file it shows all measurements and is used in
later steps. It is based on a similar file structure with row 3 showing
the mean values of the whole image. For each single segment the
measurements are listed in the second part of the file. See figure
[5.3](#fig:zo1-excel-2){reference-type="ref"
reference="fig:zo1-excel-2"} for an example of the file appearance.
Following parameters are listed (less important parameters are greyed
out):

![Example structure of the excel file containing all measurements from
the single branch analysis](media/zo1-excel2.png){#fig:zo1-excel-2
width="100%"}

::: center
+----------------------------+----------------------+-----------------------------------------------------------+
| parameter                  | unit                 | description                                               |
+:===========================+:=====================+:==========================================================+
| parameter                  | unit                 | description                                               |
+----------------------------+----------------------+-----------------------------------------------------------+
| branch number              | \-                   | Individual number of each cell border segment.            |
+----------------------------+----------------------+-----------------------------------------------------------+
| medoid                     | {pixel-position,     | coordinate of the closest element to the                  |
|                            | pixel-position}      | centroid[@reference.wolfram_2021_componentmeasurements]   |
+----------------------------+----------------------+-----------------------------------------------------------+
| outerPerimeterCount        | µm                   | number of elements adjacent to the                        |
|                            |                      | component[@reference.wolfram_2021_componentmeasurements]. |
|                            |                      | For the single branch analysis the outerPerimeterCount    |
|                            |                      | showed better results when computing the R-Index.         |
+----------------------------+----------------------+-----------------------------------------------------------+
| outerPerimeterCount-smooth | µm                   | Same as above for the smoothed segment.                   |
+----------------------------+----------------------+-----------------------------------------------------------+
| R-Index                    | \-                   | Modelling parameter showing the differences in segment    |
|                            |                      | riffle.                                                   |
+----------------------------+----------------------+-----------------------------------------------------------+
| neighbor cell number       | {#} or {#,#}         | Shows the number of the neighbour cells. When one of the  |
|                            |                      | neighbour cells couldn't be detected only one number is   |
|                            |                      | saved.                                                    |
+----------------------------+----------------------+-----------------------------------------------------------+
| GFP neighbor cell          | {Bool} or            | Returns the GFP-status of the neighbor cells, if an       |
|                            | {Bool,Bool}          | additional GFP-file is available and the processing       |
|                            |                      | option is selected. Otherwise, the table shows 'no GFP    |
|                            |                      | data'.                                                    |
+----------------------------+----------------------+-----------------------------------------------------------+
| branch orientation         | text                 | This parameter is only available when GFP-modelling is    |
|                            |                      | used. It uses the medoid of the segment to determine if   |
|                            |                      | the segment is predominantly pulled to one of the         |
|                            |                      | neighbor cells:                                           |
|                            |                      |                                                           |
|                            |                      | - non GFP cell pulls                                      |
|                            |                      |                                                           |
|                            |                      | - GFP cell pulls.                                         |
|                            |                      |                                                           |
|                            |                      | - non distinguishable: Difference too small to make       |
|                            |                      |   prediction.                                             |
|                            |                      |                                                           |
|                            |                      | - Null: only one neighbour cell detected or both with the |
|                            |                      |   same GFP-labelling (same genotype).                     |
+----------------------------+----------------------+-----------------------------------------------------------+
| branch enclosed area       | µm²                  | This parameter is only available when GFP-modelling is    |
|                            |                      | used. Both ends of the segment are connected and the      |
|                            |                      | enclosed area is computed. Only computed when two         |
|                            |                      | neighbor cells of different types are present.            |
+----------------------------+----------------------+-----------------------------------------------------------+
| pulled area                | µm²                  | Based on the enclosed area (see one above) the overlapped |
|                            |                      | area with the GFP-cell and non-GFP-cell is calculated.    |
|                            |                      | The difference between this two values is the pulled      |
|                            |                      | area. When positive the GFP-cells pulls the segment with  |
|                            |                      | the stated area. When negative the non-GFP cell pulls the |
|                            |                      | segment.                                                  |
+----------------------------+----------------------+-----------------------------------------------------------+
:::

##### zo1/processing_xlsx/\*\_raw-matrix_fullcell.mat:

This file is only created if the form analysis function is used. It
contains the shape data of each cell object. Might be helpful for
advanced morphogenesis studies, currently the file is not commonly used.

##### zo1/processing_xlsx/\*\_zo1.txt:

If no cell objects are detected in the image (e.g. unsharp microscope
image with inadequate U-Net segmentation) a text-file is created instead
of the xlsx-files containing the measurements. This way the faulty files
can easily be spotted.

## Common Errors {#sec:math-step1-errors}

Unfortunately, the execution of the Mathematica scripts is not
completely error-free. Compared to the second step in ImageJ errors are
significantly rarer. Errors are shown as red text below the error
inducing cell block (example in fig.
[5.4](#fig:mathematica-error){reference-type="ref"
reference="fig:mathematica-error"}). In most cases it helps to
completely close and restart Mathematica and the script. Get the default
version of the script to avoid unknowingly changes in the source code.
Check the folder structure and if the script has detected as much image
files as expected (number is displayed when executing the third code
block in the script). Sometimes only one image file might be faulty and
generate the error message with all other images being processed without
problems.

![Mathematica script errors lead to a red error messages below the code
block.](media/mathematica-error.png){#fig:mathematica-error
width="100%"}

# Mathematica Script Part 2 -Visualization {#cha:mathematica-part2}

This chapter covers the last step in the automatic processing pipeline
which reworks the gathered data and creates basic visualizations.

## Initial Preparation {#sec:mathematica-preparation2}

After successfully running the detection script as described chapter
[5](#cha:mathematica-part1){reference-type="ref"
reference="cha:mathematica-part1"}, the second step in Mathematica can
be executed. The 'Visualisation'-step offers two essential features. It
combines the previously generated data to create simple graphs and
statistical reports to easily see differences between genotypes or
subgroups in the datasets. Additionally, the combined data is saved in
an accessible way to use it in further statistical software. The script
is build very similar compared to the detection scripts (see section
[5.2](#sec:math-step1-scripts){reference-type="ref"
reference="sec:math-step1-scripts"} and image
[5.1](#fig:mathematica-script-screen){reference-type="ref"
reference="fig:mathematica-script-screen"}).

## Data preparation {#sec:mathematica-data-prep}

Before the scripts can be used the result excel files created with the
'Detection'-script need to be resorted into a new folder structure. The
previously used structure, that is automatically created by the ImageJ
script, is an easy way to store the image files in a logical order and
divided by different experiments. To compare various genotypes the
'Visualisation'-script needs to know which files belong together. The
disadvantage: This step needs to be done by hand as it could not be that
easily automated as the other steps. The advantage. The user can define
exactly what files or genotypes should be compared, which files should
be excluded or which different experiments should be mixed. When
comparing too many genotypes it can cause trouble with the visualization
in the autogenerated graphs. Usually 3-4 genotypes per comparison work
without a problem. Multiple comparison folders can created by once, the
scripts will automatically process them one by one. The new required
folder structure for the visualization step is built as follows:

<figure data-latex-placement="H">

</figure>

All Folders marked in red need to have the exact name, otherwise the
scripts won't work. Other folders can be individually changed by the
user, but the folder structure inside the data_input folders needs to
stay the same. The 'genotype/setting' name will be used in the graphs to
label the data. One exception are the GFP ZO-1 files. These don´t need
to be separated by genotype an should be sorted in one folder:

<figure data-latex-placement="H">

</figure>

### Different settings {#ssec:mathematica-part2-subsettings}

Depending on the settings used in the Mathematica detection script,
different result files are created. The possible combinations and the
right files for the visualization step are listed in the following part.

##### ZO-1 without single branch or GFP functionality:

Sort the '\*\_zo1.xlsx' files from the 'zo1/ processing_xlsx/'-folder in
the different genotype folders.

##### ZO-1 with single branch analysis:

Sort the '\*\_branches.xlsx' files from the
'zo1/processing_xlsx/-folder' in the different genotype folders.

##### ZO-1 with GFP analysis:

In this case the files don't need the separation into different
genotypes since the GPF information will provide this categorization
(GFP positive cells = genotype 1, GFP negative cells = genotype 2). Sort
the '\*\_zo1.xlsx' files from the 'zo1/processing_xlsx/'-folder in one
folder inside the 'data_input'-folder e.g. named 'all', as shown above
in the folder tree.

##### ZO-1 with both single branch and GFP processing:

In this case the files don't need the separation into different
genotypes since the GPF information will provide this categorization
(GFP positive cells = genotype 1, GFP negative cells = genotype 2). Sort
the '\*\_branches.xlsx' files from the 'zo1/processing_xlsx/'-folder in
one folder inside the 'data_input'-folder e.g. named 'all', as shown
above in the folder tree.

## Placing the scripts {#sec:mathematica-part2-placing}

When all comparison folders are created and the required files are
sorted in the new file structure the Mathematica scripts need to be
placed in the parent folder, as shown in the folder tree in section
[6.2](#sec:mathematica-data-prep){reference-type="ref"
reference="sec:mathematica-data-prep"}. The script will automatically
detect all 'data_input' folders.

## Run the scripts {#sec:mathematica-part2-run}

The execution of the Mathematica notebook is similar to the previous
part ([5.4](#sec:math-step1-run){reference-type="ref"
reference="sec:math-step1-run"}). Depending on the number of comparison
folders it may take a few minutes until the script is finished. Overall,
it should be much faster compared to the detection step, were
postprocessing and modeling generates a more heavy workload. Again, each
code block needs to be run separately and in order given by the script
structure.

1.  Open the script placed in the parent folder beside all the analysis
    folders.

2.  Scroll down to the 'Run' section.

3.  Right click on the first code block (preferably directly on the text
    to select the correct block) and click onto 'Evaluate Cell' in the
    dropdown menu. The first block will close all existing computation
    kernels which will help avoid side effects with previously run
    scripts.

4.  When asking 'Do you want to automatically evaluate all the
    initialization cells in the notebook' click on 'Yes'.

5.  Wait until execution is finished -- the block markers on the right
    side stays bold during the execution.

6.  Adapt the settings in the second block if required and available
    (see below for details).

7.  Evaluate the second block as described in Step 3 and 5.

8.  Evaluate the third block as described in Step 3 and 5. This will
    load all files that were selected for analysis.

9.  Evaluate the fourth block as described in Step 3 and 5. This block
    starts the processing and will generate the new output files.

10. A fifth block starts the optional 'cutoff'-analysis, which means it
    will exclude values larger than the predefined cut off. It´s
    especially useful for the R-index to exclude outlier that alter the
    visualisation.

11. Close the script when all code blocks ran successfully. The script
    file doesn't need to be saved.

## Script settings {#sec:mathematica-part2-settings}

The second code block in the 'Run'-section scripts lets the user define
parameters of the analysis step. Most of the time the default settings
are suitable and don´t need to be changed:

::: center
  parameter name      default setting                                     explanation
  ------------------- --------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  parameter name      default setting                                     explanation
                                                                          
  gfp                 False                                               Set value to True if the GFP setting was used.
  singleBranch        False                                               Set value to True if the single branch setting was used.
  fileMeanCutoff      0                                                   When using the fileMean analysis (see section [6.6.1](#ssec:mathematica-part2-output-zo1){reference-type="ref" reference="ssec:mathematica-part2-output-zo1"}) the scripts lets the user define a cut off value. Background: It could be problematic if an image with only 1 detected cell is weighted the same as a file with 20 detected cells. Images with less detected cells than the defined value are excluded.
  outliersCutoff      20                                                  Value for cut off analysis. Defines to maximum value that is included, larger values are dismissed. For R-index values larger 20 are most likely detection errors and can be excluded. Is only applied to the specific outputted pdf.
  outliersParameter   17 (for non single branch), 5 (for single branch)   Parameter that will be used for cut off analysis. Mostly used for R-index (see default), but every other parameter should work. The number is equivalent to the column number in the excel files.
:::

## Interpret output {#sec:mathematica-part2-output}

All new files are saved inside the 'data_output' folder. Depending on
the used script and input files many different excel- and pdf-files are
created. For the first time this might look overwhelming, but behind
that is a clear pattern based on a couple different analysis modes. In
favour of a simple and fast way of reviewing the datasets all possible
parameters are created and can be inspected with a few clicks.
Therefore, the user doesn't need to specify the parameters when running
the scripts and can decide later which parameters are more relevant for
the exact question. For the daily work only a few parameters might be
relevant and other files can be ignored.

### ZO-1 - Output {#ssec:mathematica-part2-output-zo1}

Depending on the different settings we can apply for the Zo-1 detection
our visualization script will generate slightly different output. The
parameters are described in subsection
[5.6.1.1](#ssaec:math-step1-zo1-excel1){reference-type="ref"
reference="ssaec:math-step1-zo1-excel1"} and
[5.6.1.2](#ssaec:math-step1-zo1-excel2){reference-type="ref"
reference="ssaec:math-step1-zo1-excel2"}.

#### ZO-1 without single branch or GFP functionality {#ssec:mathematica-part2-output-zo1-2}

The standard and most used setting will generate 3 different types of
files:

##### Excel-files:

These files simple reformat the inputted data, that is divided in single
files from each image, into one file. The number and parameter name are
shown as a first part of the file name. Every column inside the file
corresponds to one image file with all values listed in this row. These
newly created files can be easily used in other software.

##### Cell level PDF-files:

These files give a simple visualization and statistical analysis of the
data and the particular parameter. Each object is included in the
visualization with its own data point. This leads to a wider spreading
but represents the whole biological appearance. In addition to the
cell_level'-prefix the filename shows the name and number of the
parameter. Inside this PDF-file (example shown in
fig.[6.1](#fig:zo1-export-pdf){reference-type="ref"
reference="fig:zo1-export-pdf"}) a smooth histogram (y-axis values are
arbitrary) and a point cloud plot gave an easy to view visualization of
the dataset. Each point in the cloud plot represents one cell object.
The mean value of the whole dataset is shown as a bold bar in the cloud
plot. Below that, the first table shows the key parameters of the
analyzed dataset and genotypes. A second table shows an automatically
generated statistic analysis between the genotypes. Additionally, the
cut off analysis can be run that excludes measurements larger than the
predefined value and negative values. The suffix 'cutoff' followed by
the cutoff-value is included in the file name.

![Example of the output PDF that shows the measurements of the
cell-level ZO-1 analysis](media/cell-level-zo1.png){#fig:zo1-export-pdf
width="70%"}

##### File level PDF-files:

Like the cell level files but only the mean values from each image are
used -- every image creates one data point. When a specific
'fileMeanCutoff'-value is defined, images with less cell objects are
excluded. The cut off value is also stated in the file name.

#### ZO-1 with single branch analysis {#ssec:mathematica-part2-output-zo1-3}

The single branch analysis outputs an object-level PDF-file showing the
visualized measurements and an excel file containing the raw data of the
R-index values. Other parameters are not collected. The cut off analysis
(see above) can also be applied to exclude values larger than the
predefined threshold, which might lead to a nicer visualization.
Negative values (are considered as modeling errors) are excluded for all
visualizations and in the raw data excel file.

#### ZO-1 with GFP processing {#ssec:mathematica-part2-output-zo1-4}

This setting generates an output very similar to the ZO-1 without single
branch and GFP functionality. The genotypes are not defined by the
folder structure since the files provide the GFP true or false
classification. File level analysis is not possible in this setting.

#### ZO-1 with both single branch and GFP processing {#ssec:mathematica-part2-output-zo1-5}

This analysis mode outputs multiple object-level PDF-files showing the
visualized measurements and excel files containing the raw data of the
R-index values, the branch orientation (only raw data excel file) and
the 'pulled area' parameters. The cut off analysis (see above) can also
be applied to exclude values larger than the predefined threshold.
Negative values (are considered as modeling errors) are excluded for all
visualizations and in the raw data excel file. File level analysis is
not possible in this setting.

## Common errors {#ssec:mathematica-part2-errors}

As described in section
[5.7](#sec:math-step1-errors){reference-type="ref"
reference="sec:math-step1-errors"} the execution of the Mathematica
scripts is not error-free. In most cases it helps to completely close
and restart Mathematica and the script. Get the default version of the
script to avoid unknown changes in the source code in the previously
used one. Check the folder structure of the input data and if the script
has detected as many processing folders as expected (is displayed when
executing the third code block in the script). Sometime only one excel
file might be faulty and leads to an error message. If doable check all
input files to detect abnormalities in the table structure.

# Acknowledgments {#cha:acknowledgments}

Thanks to all laboratory members who provided datasets for training,
testing and figure creation.


# Bibliography

ComponentMeasurements. Wolfram Research. 2017. URL: https : / / reference . wolfram . com /
language/ref/ComponentMeasurements.html (visited on 12/17/2021).

Falk, Thorsten. U-Net Segmentation Plugin für ImageJ. [online]. 2019. URL: https : / / sites .
imagej.net/Falk/plugins/ (visited on 08/01/2022).

Falk, Thorsten et al. “U-Net. Deep learning for cell counting, detection, and morphometry”. eng. In:
Nature methods 16.1 (2019). Journal Article Research Support, Non-U.S. Gov’t, pp. 67–70. DOI:
10.1038/s41592-018-0261-2. eprint: 30559429.
