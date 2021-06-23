/* 
 PFIA Step 3: Count and cell density analysis:
- This macro count cells using the Analyze Particle plugin. 
- To use this macro, the user must have a set of atlas defined brain regions of interest (ROIs). 
  See "pfia_step2_warp-register_brain_section.imj" for this.
- The output of the macro is a ".csv: file stored in the image directory.
- This macro is has been tested with brain sections with mainly somatic neuronal markers such as parvalbumin.
- For cell counts involving high density markers, such as NeuN, see "pfia_step_3_count_neun_cells.ijm".

 Code contributors: Simona D. Frederiksen, Juan C. Sanchez-Arias
 Affiliations: University of Victoria, Division of Medical Sciences, Swayne Lab
 
 License: GNU General Public License v3.0
 
 Github repository: https://github.com/SwayneLab/pfia

 To report issues, comment, or suggest improvement pull a request through the github repository or contact juansa@uvic.ca
*/

/*==========================================================================
 The below script is functional. It doesn't save individual cell ROI,
 but it can iterate through multiple atlas-based ROIs at once. 
============================================================================*/

/*
 Open maximum intensity projection of an image with the channel containing the singal of cells to analyze.
 For example: parvalbumin, NeuN.
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


//1) Subtract background
/*
 Gaussian-blur background subtraction step
 */
run("Smooth");
run("Duplicate...", "title=img_duplicate");
img_duplicate = getTitle();
selectWindow("img_duplicate");
run("Gaussian Blur...", "sigma=10");
imageCalculator("Subtract create", img_name, img_duplicate);
close(img_name);
close(img_duplicate);
img_sub_name = getTitle();

//2) Perform global thresholding
setAutoThreshold("Moments dark");
run("Convert to Mask");
run("Watershed");

img_thresholded = img_name_only + "_whole_threshold.jpg";  
saveAs("jpeg", img_path_parent + fs + img_thresholded); 

//3) Count cells with atlas-based brain region ROIs iteration. It doesn't save counted cells as indivudal ROIs
waitForUser("Open and select ROI(s).\n \nRemove from the 'ROI Manager' any ROI that will not be analyzed"); // Waits for the user to open load ROI(s) of interest

atlas_roi = roiManager("count");
for (roi = 0; roi < atlas_roi; roi++) {
	roiManager("Select", roi);
	roi_name = Roi.getName;
	// Setting measurements and saving ROI area results
	run("Set Measurements...", "area redirect=img_sub_name decimal=3");
	run("Measure");
	saveAs("Results", img_path_parent + fs + img_name_only + "_area_" + roi_name + ".csv");
	close("Results"); 
//	roiManager("reset");
//	run("Analyze Particles...", "size=35-Infinity pixel circularity=0.5-1.00 show=Outlines clear summarize add");
	run("Analyze Particles...", "size=35-Infinity pixel circularity=0.5-1.00 show=Outlines clear summarize");
	
	nROIs=roiManager("count");
	selectWindow(img_sub_name);
	
	//Save ROIs - region and cells
	run("Select All");
	cell_count_rois = img_name_only + "_cell_count_roi-set.zip";
//	roiManager("Save", img_path_parent + fs + cell_count_rois);
//	roiManager("reset");
//	close("Result of " + img_name);
	selectWindow("Drawing of Result of " + img_name);
	saveAs("jpeg", img_path_parent + fs + img_name_only + "_cell_count_outline_image_" + roi_name + ".jpg");
	close("Drawing of Result of " + img_name);
	
	//Save summary cell count
	selectWindow("Summary");
	cell_count_results = img_name_only + "_summary_cell_count";
	saveAs("Results", img_path_parent + fs + cell_count_results + "_" + roi_name+ ".csv");
	run("Close"); 
}

// Close all windows 
close("ROI Manager");
close("*");

 // Fress memory
run("Collect Garbage");

/*============================================================================
Use this chunk below if you don't need to ierate through several atlas-based ROI
and want to save individual counted cells as a ROI set (.zip file).
==============================================================================*/

/*
//3) Count cells within ROI of interest and saves cells as individuals ROIs in a set
roi_name = Roi.getName;

//Analyze atals-based ROI (ADD measure area of ROI)
roiManager("Select", roi_name);

// Setting measurements and saving ROI area results
run("Set Measurements...", "area redirect=img_sub_name decimal=3");
run("Measure");
saveAs("Results", img_path_parent + fs + roi_name + ".csv");
close("Results"); 
roiManager("reset");
run("Analyze Particles...", "size=35-Infinity pixel circularity=0.5-1.00 show=Outlines summarize add");
nROIs=roiManager("count");
selectWindow(img_sub_name);

//Save ROIs - region and cells
run("Select All");
cell_count_rois = img_name_only + "_cell_count_roi-set.zip";
roiManager("Save", img_path_parent + fs + cell_count_rois);
roiManager("reset");
close("ROI Manager");
close("Result of " + img_name);
selectWindow("Drawing of Result of " + img_name);
saveAs("jpeg", img_path_parent + fs + img_name_only + "_cell_count_outline_image.jpg");
close("Drawing of Result of " + img_name);

//Save summary cell count
selectWindow("Summary");
cell_count_results = img_name_only + "_summary_cell_count";
saveAs("Results", img_path_parent + fs + cell_count_results + "_" + roi_name+ ".csv"); 
run("Close");
*/