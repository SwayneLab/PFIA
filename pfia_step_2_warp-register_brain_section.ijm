/* 
 PFIA Step 2: Warp and register brain section:
 - This ImageJ Macro script exports files from proprietary microscope software into .tif files. If an image is a stack
 or has multiple channels, it will save maximum projections of image and if it has more than one channel, it will save individual stacks
 and maximum projections of each image. The script also pulls the metadata from the file and saves it as a .csv file.
 The script also pulls histogram values of individual channel images and saves them as .csv. These latter .csv files with 
the histogram information can be plotted in many freely and licensed statistical or spreadsheet softwares.

 Code contributors: Juan C. Sanchez-Arias, Simona D. Frederiksen 
 Affiliations: University of Victoria, Division of Medical Sciences, Swayne Lab
 
 License: GNU General Public License v3.0
 
 Github repository: https://github.com/SwayneLab/pfia

 To report issues, comment, or suggest improvement pull a request through the github repository or contact juansa@uvic.ca
*/

/*
 Open maximum intensity projection of a nuclear marker (e.g., Hochest) 
 to register brain section to mouse brain coronal section
 */

#@ String (value = "Browse a maximum projection image to register to the unified altas drawing", visibility = "MESSAGE") msg
#@ File (style="open") img_path
#@ File (style="open") atlas_drawing_path

fs = File.separator;
img_path_parent = File.getParent(img_path);

	/*
	 Creates a dialog window to store the file extension from user input 
	*/
open(img_path);
open(atlas_drawing_path);
run("Tile");

img_name = File.getName(img_path); // Sets Img_name object with the name of the opened file
atlas_drawing_name = File.getName(atlas_drawing_path);
selectWindow(img_name);
getDimensions(width, height, channels, slices, frames);

/*
 Creates a dialog window to get rotation angle and flip information from user. 
*/
flip_types = newArray("Don't flip", "Vertically", "Horizontally");
Dialog.create("Rotate the acquired brain section to match the orientation of the vector drawing atlas image");
Dialog.addString("Enter angle value: ", "0");
Dialog.addMessage("(positive integers rotate the image clockwise,\nnegative intergers rotate the image counter clockwise,\ntype '0' for no rotation)");
Dialog.addChoice("Flip?", flip_types);
Dialog.show();
angle = Dialog.getString();
flip_choice = Dialog.getChoice();
run("Rotate... ", "angle=" + angle + " grid=1 interpolation=Bilinear");
if (flip_choice == "Vertically"){
	run("Flip Vertically");
} else if (flip_choice == "Horizontally"){
	run("Flip Horizontally");
} else {
	}

// Checks with user if images are properley oriented to start registration with Big Warp. If 'OK', a Big Warp instance is opened
waitForUser("Are the images properly oriented to register using Big Warp?\nBest results are accomplished when using 15=20 landmarks\n \nTo begin placing landmarks hit the 'spacebar'\n \nZoom in and out with the scroll wheel\n \nRotate the image by dragging with the 'left click'\n \nMove the image around with the 'right click'\n \nHit the 'spacebar' again to quit landmark mode.\n \nFor more information about BigWarp go to:\nhttps://imagej.net/plugins/bigwarp");
run("Big Warp", "moving_image=" + atlas_drawing_name + " target_image=" + img_name + " moving=[] moving_0=[] target=[] target_0=[] landmarks=[] apply");
waitForUser("Once your are finished placing the landmarks, go to the moving image window\nand go to 'File -> Export as ImagePlus'\n \nSelect 'Target' for 'Resolution' and 'Field of view'\nChoose nereast neighbour for 'Interpolation'\n \nOnce the new warped image is produced and you are happy with the outcome,\nclose 'BigWarp' Windows and hit 'OK' on this window.");

close(atlas_drawing_name); // Close un-warped vector drawing

/*
 Binarizes and skeletonizes the warped atlas vector drawing. It includes a set o functions to draw a rectangle around the image to close selections
 */
selectWindow(atlas_drawing_name + " channel 1_" + atlas_drawing_name + " channel 1_xfm_0");
getDimensions(width, height, channels, slices, frames);
run("Specify...", "width="+ (width-1) + " height=" + (height-1) + " x=" + (width/2) + " y="+ (height/2) +" centered");
run("Draw", "slice");
run("Select None");
run("Auto Threshold", "method=Triangle");
run("Invert");
run("Skeletonize");
run("Images to Stack", "method=[Scale (smallest)] name=Stack title=[]");

setTool("wand"); // Activates the Wand tool

waitForUser("Use the Wand tool to select the regions of interests (ROIs) and save them to the 'ROI Manager'.\n \nKeyboard shortcut: 'T'\nYou can rename each ROI within the 'ROI Manager' to match their name with their description (e.g., 'layer 1')\nYou can combine multiple regions of interest by selecting them with the 'Wand tool' while pressing 'Shift'\nor by selecting them within the 'ROI Manager' and applying the 'OR' function.\n \nWhen you are finished adding and managing the ROIs to the 'ROI Manager',\nclick 'OK' on this window to save the ROIs to the file directory.\n \nNote: Clicking 'OK' will also close all the windows.");
	
roiManager("save", img_path_parent + fs + "atlas_rois.zip");
close("*"); // Closes all image windows

/*
 Creates Dialog to check with user how to poceed after finishing adding the desired ROIs
 */
options = newArray("No", "Yes");
Dialog.create("Notice");
Dialog.addChoice("Do you want to close the 'ROI Manager'?", options);
Dialog.show();
option = Dialog.getChoice();
if (flip_choice == "No"){
	roiManager("save", img_path_parent + fs + "atlas_rois.zip"); // Saves ROIs to the image directory as "atlas_rois.zip"
	close("*"); // Closes all image windows
} else if (flip_choice == "Yes"){
	roiManager("save", img_path_parent + fs + "atlas_rois.zip");
	close("*"); // Closes all image windows
	close("ROI Manager"); // Closes ROI Manager
}

// close("ROI Manager"); // Closes ROI Manager

// Frees memory
run("Collect Garbage");