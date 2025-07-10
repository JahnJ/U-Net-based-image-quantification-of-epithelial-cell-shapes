/*U-Net Processing Library
 *
 *This macro can be used to process and segment multiple microscopic images files at once with the U-Net plugin. Please look into the additional documentation for
 *references regarding the folder structure and image capturing settings. This macro provides multiple modes for different image types
 *(normal, stitched, GFP) that can be selected when running the macro.
 *This macro is tested with the ImageJ version for Windows. Running on unix system might need adaptions in the window closing and selecting routines.
 *
 * Author: Jahn, Johannes
 * Date: 02/2025
 * Code version: 1
 * E-Mail: Johannes.Jahn@uniklinik-freiburg.de
 * 
 */

//Individual Settings; need to be adjusted for each machine and remote server:
//for file paths use "/" as dividing symbol, "\" might cause problems

//U-Net remote server settings for SSH-connection; for server installation visit: https://lmb.informatik.uni-freiburg.de/resources/opensource/unet/
hostname='';
username='';

//RSA Keyfile for ssh authentication - Paths needs to be adapted for each remote machine
RSAKey='';

//Filepath for the U-Net models, weights file is located on the remote server
model='';
weights='';

//processFolder file path; is located on the remote server
processFolder='';

//define memory limit and tile size, based on the memory of the Server-GPU (eg. NVIDIA 1080Ti 11GB); don´t use complete memory and add overhead capacity
//the best settings can easily be tested with the U-Net Plugin without this macro
memory='10000';
tile_size='996x996';
//defines the number of files that are processed and send to the remote host at once. Might be adjusted depending on hardware and image size (default: 200 / 10)
processing_steps=200;
processing_steps_stichted=10;

//end individual settings


//Create dialog input the relevant information for processing
Dialog.create("U-NET Processing Library");
Dialog.addMessage("This script can be used to process multiple images via U-Net\n \n Please have a look at the documentation for further informations\n \n");
Dialog.addChoice("Image-Type:", newArray("Zo-1"));
Dialog.addNumber("Channel:", 0);
Dialog.addNumber("GFP-Channel:", 0);
Dialog.addCheckbox("Stitched", false);
Dialog.addCheckbox("Save GFP-Channel", false);
Dialog.addCheckbox("Save scores", false);
Dialog.show();

//create variables for the dialog-values; for details behind the values see further code comments
type = Dialog.getChoice();
C_Image = Dialog.getNumber();
C_GFP = Dialog.getNumber();
stitched = Dialog.getCheckbox();
gfp = Dialog.getCheckbox();
scores = Dialog.getCheckbox();

//open a dialog to define the input-diretory. All subfolders in this directory will be processed (correct folder-structure required)
input_dir = getDirectory("Input directory");

//multiple subfolders are created for the U-Net and mathematica output; this arrays define the names, the "createDir" function creates the subfolders
var foldernames_type = newArray("zo1_seg/","segmented_overlay/","processing/","processing_overlay/","processing_xlsx/","zo1_seg_score/","gfp/");
type="zo1/";

//define arrays for storing filenames, paths and foldernames;
var filename=newArray();
var filepath=newArray();
var foldername=newArray();

//define cropping variables for stitched images with borders; will be adjusted later in the "cropStitched" function
var x1=0;
var y1=0;
var x2=0;
var y2=0;

//the U-Net plugin only accepts settings as a string variable; so the boolean-variable set in the dialog is converted to a string variable
if(scores==true) scoresVar='true';
else scoresVar='false';

// Check if requiered files for processing exists, otherwise exit the macro with an error message
if (!File.exists(model) || !File.exists(RSAKey)){
	exit("Weight-File or RSAKey-File on this machine not found. Please double check filepaths in the beginning of the source code!")
}

//when working with stitched images, we add a substring to the type. step-size is reduced to avoid memory-overflows (U-Net/ImageJ/Java can´t allocate more than 4GB)
if (stitched==true) {
	//substring returns the type without the "/"
	type = substring(type,0,lengthOf(type)-1)+"_stitched/";
	step = processing_steps_stichted;
}
else {step=processing_steps;}

//start processing
processComplete(input_dir);

//main processing function
function processComplete(input){
	//BatchMode speeds up the script by not displaying the images
	setBatchMode(true);
	//lets start clean: close all other images that can distract the processing
	run("Close All");
	//searches for all *.czi images in the respective subfolders; saves filepath and foldernames in the predefined arrays (see function details below)
	find(input);

	//info-dialog: show number of found files for processing. If no files are found (likely wrong folder structure) exit the script and display an error message
	if(filepath.length >=1){
		waitForUser(filepath.length+" files are found for processing.\n\nAll steps are executed automatically.\n\nPlease do not perform other tasks on this machine.");
	}
	else {
		exit("No files found! Please double check input folder and necessary subfolders names. See documentation for further details.")
	}
	
	//problem: when processing very large datasets U-Net/ImageJ/Java suffers from memory overflows and slow processing. Therefore the dataset is divided into smaller
	//parts. The step size is defined above
	start=0;
	end=step-1;
	//for small datasets adapt the "end"-variable to the number of files; end+1 case: avoids creating parts with only 1 image
	if(end > filepath.length-1 || end+1== filepath.length-1){end=filepath.length-1;}

	//stitched images containing multiple small images oftens have a black border (e.g. when generated by a Zeiss microscop)
	//to determine the size of the black borders an image is opened; the "cropStitched" function computes the values
	if (stitched==true) {
		//nImages returns the number of open images. This is nessecary for the "closeWindow" function to close to correct window/channel
		F_vor = nImages();
		open(filepath[0]);
		F_nach= nImages();
		closeWindow(F_vor,F_nach, C_Image);
		cropStitched();
		close();
	}

	//do-loop for U-Net processing. The loop will be run multiple times, until all image-packages are finished
	do {
		//open all images (amount depending on step-value; openImage with "true" saves the filename in an separate array)
		for (i=start; i<=end; i++) {openImage(filepath[i],true,C_Image);}

		//build a stack with all images
        run("Images to Stack", "name=Stack title=[] use");
	
		//start the U-Net segmentation, variables are defined at the beginning of the script and may be changed based on the server and client configurations;
		//for stitched images use the tile shape option instead of the memory parameter. When using the memory parameter the U-Net plugin will set the
		//tile shape based on this value. On stitched images this might lead to very small tile shapes and long processing times. Hardcoding this value will fix this
		if (stitched==true) {
			call('de.unifreiburg.unet.SegmentationJob.processHyperStack', 'modelFilename='+model+',Tile shape (px):='+tile_size+',weightsFilename='+weights+',gpuId=GPU 0,useRemoteHost=true,hostname='+hostname+',port=22,username='+username+',RSAKeyfile='+RSAKey+',processFolder='+processFolder+',average=none,keepOriginal=true,outputScores='+scoresVar+',outputSoftmaxScores=false');
		}
		else {
			call('de.unifreiburg.unet.SegmentationJob.processHyperStack', 'modelFilename='+model+',Memory (MB):='+memory+',weightsFilename='+weights+',gpuId=GPU 0,useRemoteHost=true,hostname='+hostname+',port=22,username='+username+',RSAKeyfile='+RSAKey+',processFolder='+processFolder+',average=none,keepOriginal=true,outputScores='+scoresVar+',outputSoftmaxScores=false');
		}

		//score-images are returned as a 2 channel hyperstack, that need to be reduced; can be used for validating the U-Net results
		if (scores==true) {
			selectWindow("Stack - 32-Bit - reordered - rescaled (xy) - normalized - score");
			run("Reduce Dimensionality...", "frames");
		}

		//save all segemented/score images in the corresponding subfolder
		for (i=start; i<=end; i++) { 
			//the slice is selected ("i-start": returns the correct number of the position in the stack independent of the current image-package;
			//the actual value of "i" is later user the select the names/foldernames in the array where the position in the whole dataset is relevant
			//and we need to know which image-package is currently processed
			//"+1" because the numbers of images in a stack start with "1" and not "0"
			//the metadata is changed to name the image after the original filename + suffix;
			//duplicate returns a single image out of the whole stack, that is saved as a single tif file in the 
			selectWindow("Stack - 32-Bit - reordered - rescaled (xy) - normalized - score (segmentation)");
			setSlice((i-start)+1);
			setMetadata("Label", filename[i]+"_segmented");
			run("Duplicate...", "use");
			saveAs("Tiff", foldername[i] + foldernames_type[0] + filename[i] + ".tif");
			close();
			//same for the score-image, if desired
			if (scores==true) {
				selectWindow("Stack - 32-Bit - reordered - rescaled (xy) - normalized - score");
				setSlice((i-start)+1);
				setMetadata("Label", filename[i]+"_score");
				run("Duplicate...", "use");
				saveAs("Tiff", foldername[i] + foldernames_type[5] + filename[i] + "_score.tif");
				close();
			}
		}

		//close all images
		run("Close All");

		//start and end-point are adjusted for the next image-package, if we already reached the end, set -1 to exit the loop (see below)
		if(end==filepath.length-1){
			end=-1;
		}
		else {
		start=start+step;
		end=end+step;
		//adapt the "end"-variable to the number of files if the remaining images are less then the step size;
		//end+1 case: avoids creating parts with only 1 image
		if(end > filepath.length-1 || end+1== filepath.length-1){end=filepath.length-1;}
		}
	}
	//exit-statement for the previous do-loop
	while(end!=-1);

	//generate a verification overlay with the original image and the U-Net output
	generateOverlay();
	//create log-file
	createLog();
	//show finish dialog
	waitForUser("Finished");
}

//helper-function for recursive searching of all subfolders, that contain *.czi-images; needs to be adapated for other microscop images types
//input: user selected starting directory or daughter folder for recursive runs
function find(input) {
	//get a list with all files/folders in the input folder
	folderlist = getFileList(input);
	//check for all elements; if it´s a folder and can be starting point for the next run of the find-function to dig deeper in the folder structure
	//when a folder with the correct name is found (dependent on the "type"-variable), the buildList function is started to search for czi-files (see below);
	//all other files are ignored
	for (i=0; i<folderlist.length; i++) {
		if (endsWith(folderlist[i], "/")){find(""+input+folderlist[i]);}		
		if (endsWith(folderlist[i], type)){buildList(input+folderlist[i]);}      
	}
} 

//helper-function to generate foldername/filepath arrays based
//input: folder named after the type we want to process found by the "find"-function above
function buildList(input) {
	//create all processing-subfolders with another helper-function
	createDir(foldernames_type,input); 
	//get a list with all files/folders
	list = getFileList(input);
	//remove all unwanted files and subfolders from our list, CAVE: you need to specifiy the filetype e.g. ".czi", this string is case-sensitive! (.CZI won´t work)
	//add the files to the predefined arrays
	for(i=0;i<list.length;i++){
		if(endsWith(list[i],".czi")){
			foldername=Array.concat(foldername,input);
			filepath=Array.concat(filepath,input + list[i]);
		}
	}
}

//helper function that checks if the subfolders are already exisiting, otherwise they are created
//names: foldernames as defines above for the selected processing type 
//inputFolder: folder named after the type we want to process
function createDir(names, inputFolder) {
	for (i=0; i<names.length; i++){
		if (!File.exists(inputFolder+names[i])) { File.makeDirectory(inputFolder+names[i]); }
	}
}

//helper function for image opening
//path: file path of the image; save_array: if true the name of the image is saved to an array (should only be true once in the whole macro)
//channel: desired channel number that was inputted in the user dialog; is used to close all other image channels
function openImage(path,save_array,channel) {
		//count the number of images before and after opening the new file, we need to know the differenz to close unnecessary channels
		img_before = nImages();
		open(path);
		img_after= nImages();
		//calls the helper function to close all unnecessary channels
		closeWindow(img_before,img_after, channel);
		//when we work on stitched images, the image need to be croped
		if(stitched == true) {
			selectImage(img_before+1);
			//crop out parts of the black border; won´t crop all since the borders are irregular; additional steps are needed
			run("Select Bounding Box (guess background color)");
			run("Crop");
			//values are computed with the "cropStitched" function
			makeRectangle(x1,y1,x2,y2);
			run("Crop");
		}
		//for the main image loading we save the filename to an array (the file suffix (e.g. ".czi") is deleted)
		//"-4" might be changed when the file suffix is changed to a shorter/larger one
		if(save_array==true) {
			filename_short=substring(File.name,0,lengthOf(File.name)-4);
			filename = Array.concat(filename,filename_short);
		}
}

//helper-function that closes all unwanted image channels. Be sure, that the image is opened to separate image channels/windows
//(can be changed in the Bioformats Plugin; might not be necessary for all microscopic images)
//before: number of img-windows before the new image is opened; after: number of img-windows after opening the new image; C: channel number we want to process
function closeWindow(before,after,C) {
	//"i--" to walk the for-loop in reverse; otherwise this won´t work
	for (i = (after-before); i > 0; i--) {
		if(i!=(C+1)) {
			selectImage(before+i);
			close();
		}
	}
}

//helper function for cropping stitched images with black borders; will compute and save the values later needed for cropping
function cropStitched() {
	//define variables to store the width and height values of the black borders
	cut_width=newArray(4);
	cut_height=newArray(4);

	//crop out parts of the black border; won´t crop all since the borders are irregular; additional steps are needed
	run("Select Bounding Box (guess background color)");
	run("Crop");
	getDimensions(imgwidth, imgheight, channels, slices, frames);

	//select the image corner points with the magic wand to get a selection of the black border; write width and height values to the array
	doWand(0, 0);
	getSelectionBounds(x, y, cut_width[0], cut_height[0]);
	doWand(0, imgheight-1);
	getSelectionBounds(x, y, cut_width[1], cut_height[1]);
	doWand(imgwidth-1, imgheight-1);
	getSelectionBounds(x, y, cut_width[2], cut_height[2]);
	doWand(imgwidth-1, 0);
	getSelectionBounds(x, y, cut_width[3], cut_height[3]);

	//sort array; the secound value will be the relevant value for cropping
	Array.sort(cut_width);
	Array.sort(cut_height);
	
	//check if values are unequal to 1, then add a 25 pixel margin 
	//otherwise the image may not have a black border and should not be cropped, so the values are set to 0
	if (cut_width[1]!=1){cut_width[1]=cut_width[1]+25;}
	else {cut_width[1]=0;}
	if (cut_height[1]!=1){cut_height[1]=cut_height[1]+25;}
	else {cut_height[1]=0;}

	//compute and save the values to later make a rectangle for cropping
	x1=cut_width[1];
	y1=cut_height[1];
	x2=imgwidth-2*cut_width[1];
	y2=imgheight-2*cut_height[1];
}

//overlays the original image with the U-Net-segmentation to get a verification-image
//this function gets exectued after all image-packages are processed, therefore all images in the user selected folder are again opened to be overlayed
function generateOverlay() {
	for (i = 0; i < filepath.length; i++) {
		//open the original microscopic image and apply basic adjustments; rename to other name for better handling
		openImage(filepath[i],false,C_Image);
		getDimensions(width, height, channels, slices, frames);
		run("Enhance Contrast...", "saturated=0.3");
		run("8-bit");
		rename("overlay1");

		//open the segmented U-Net image, "foldernames_type[0]" is the folder for the segmented image
		file_proc=foldername[i] + foldernames_type[0] + filename[i] + ".tif";
		open(file_proc);
		//rescaling to the dimensions of the original image; the U-Net output can vary by a few pixels; overlayed images need the same size
		run("Scale...", "x=- y=- width="+width+" height="+height+" interpolation=Bilinear average create");
		run("8-bit");		
		rename("overlay2");

		//overlay the images (segmented (overlay2) on the green channel (c2)) and save to jpg
		run("Merge Channels...", "c2=[overlay2] c4=[overlay1] create");  
		saveAs(".jpg",foldername[i] + foldernames_type[1] + filename[i] + "_overlay.jpg");

		//when the image files contain an gfp channel this can be additionally saved; open image, basic adjustment and saving
		if(gfp==true){
			openImage(filepath[i],false,C_GFP);
			run("Enhance Contrast...", "saturated=0.3");
			run("8-bit");
			saveAs("Tiff", foldername[i] + foldernames_type[6] + filename[i] + "_gfp.tif");
		}
		//close all images for the next for-loop-pass
		run("Close All");
		
	}
}

//helper-function, that creates a log file, when the whole script is finished; contains the date and the name of the U-Net network
function createLog() {
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	//+1, because month starts with 0
    timeString = "Date: "+dayOfMonth+"-"+month+1+"-"+year;		

	//add the information to the txt-file; "\t": line break
    path = input_dir+File.separator+"log.txt";
    File.append(timeString+"\t", path);
	File.append(model+"\t", path);
	File.append("\t ", path);
}

