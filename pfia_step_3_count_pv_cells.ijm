/* 
 PFIA Step 3: Count and cell density analysis:
 - This macro count cells using the Analyze Particle plugin. 
 - To use this macro, the user must have a set of atlas defined brain regions of interest (ROIs). 
   See "pfia_step2_warp-register_brain_section.imj" for this.
 - The output of the macro is a ".csv: file stored in the image directory.
 - This macro has been tested with brain sections labelled with a high density neuronal marker, such as NeuN.
 - For an example of a somatic marker, such as parvalbumin, see "pfia_step_3_count_pv_cells.ijm".
 - The cell count is derived from the Find Maxima count fuinction
 - A segmented watershed image is produced at the end (this can take some time depending on the size of the image)

 Code contributors: Simona D. Frederiksen, Juan C. Sanchez-Arias
 Affiliations: University of Victoria, Division of Medical Sciences, Swayne Lab
 
 License: GNU General Public License v3.0
 
 Github repository: https://github.com/SwayneLab/pfia

 To report issues, comment, or suggest improvement pull a request through the github repository or contact juansa@uvic.ca
*/



/*=============================================
Count cells using NeuN signal and Find Maxima
==============================================*/

/*
 Open maximum intensity projection of an image with the channel containing the singal of cells to analyze.
 For example: NeuN.
 */

// Get image and directory information
img_path = File.openDialog("Choose the file to analyze"); 
img_name = File.getName(img_path); // Sets img_name object with the name of the opened file
fs = File.separator;
img_path_parent = File.getParent(img_path);
open(img_path);
img_name_only = File.nameWithoutExtension;
selectWindow(img_name);

/*
 Creates a dialog window to get rotation angle and flip information from user. 
*/
flip_types = newArray("Don't flip", "Vertically", "Horizontally");
Dialog.create("Rotate the acquired brain section to match the orientation of the atlas-generated ROIs");
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


/*=====================================
 Image processing steps
======================================= */
//1) Subtract background
run("Duplicate...", "title=img_duplicate");
close(img_name);
selectWindow("img_duplicate");
run("Smooth");
run("Subtract Background...", "rolling=100");

//2) Apply median filter = replaces each pixel with the median value in its 3 × 3 neighborhood (for radius = 1).
run("Median...", "radius=1");
run("Enhance Contrast...", "saturated=0.3");
run("Sharpen");

//Select desried atlas-based ROIs
waitForUser("Open and select ROI(s).\n \nRemove from the 'ROI Manager' any ROI that will not be analyzed"); // Waits for the user to open load ROI(s) of interest

atlas_roi = roiManager("count");
for (roi = 0; roi < atlas_roi; roi++) {
	roiManager("Select", roi);
	roi_name = Roi.getName;
	run("Set Measurements...", "area redirect=img_duplicate decimal=3");
	run("Measure");
	saveAs("Results", img_path_parent + fs + img_name_only + "_area_" + roi_name + ".csv");
	close("Results");
	
	run("Set Measurements...", "area display redirect=None decimal=3");
//	run("Find Maxima...", "prominence=15 exclude output=Count"); // Prominence values between 10-20 worked best in our hands
//	selectWindow("Results");

	selectWindow(img_duplicate);
	roiManager("select", roi);
	run("Crop");
	run("Make Inverse");
	run("Clear", "slice");
	run("Select None");

	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input': '" + img_duplicate + "', 'modelChoice':'DSB 2018 (from StarDist 2D paper)', 'normalizeInput':'true', 'percentileBottom':'80.0', 'percentileTop':'99.0', 'probThresh':'0.125', 'nmsThresh':'0.35000000000000003', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

	selectWindow("Label Image");
	saveAs("tif", img_path_parent + fs + img_name_only + "_roi_isolated_image_" + roi_name + ".tiff");
	
	//Save ROIs - region and cells
	nROIs=roiManager("count");
	roiManager("select", Array.getSequence(nROIs));
	cell_count_rois = img_name_only + "_cell_count_roi-set.zip";
	roiManager("Save", img_path_parent + fs + cell_count_rois);
	roiManager("Measure");
	saveAs("Results", img_path_parent + fs + cell_count_results + "_" + roi_name+ ".csv");

	roiManager("reset");
		
	close("Results");
}

// Close all windows 
close("ROI Manager");
close("*");

 // Fress memory
run("Collect Garbage");
