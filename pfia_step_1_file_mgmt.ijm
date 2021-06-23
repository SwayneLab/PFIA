/* 
 PFIA Step 1: File management:
 - This ImageJ Macro script exports files from proprietary microscope software into .tif files. If an image is a stack
 it will save maximum projections of image and if it has more than one channel, it will save individual stacks
 and maximum projections of each image. The script pulls the metadata from the file and saves it as a .csv file.
 The script also pulls histogram values of individual channel images and saves them as .csv. These latter .csv files 
 (containing histogram information) can be plotted in many free, licensed statistical or spreadsheet softwares.

 Code contributors: Juan C. Sanchez-Arias, Simona D. Frederiksen, Hai Lam Nguyen
 Affiliations: University of Victoria, Division of Medical Sciences, Swayne Lab
 
 License: GNU General Public License v3.0
 
 Github repository: https://github.com/SwayneLab/pfia

 To report issues, comment, or suggest improvement submit a request through the github repository or contact juansa@uvic.ca
*/

/* Step 1: Obtaining files
 This portion takes a proprietary microscopy software file (e.g., .lif) containing merged TileScans
 and outputs a flatten max-projected RGB image in .lpeg format and .tif files of stacks and maximum projections of 
 each image and its individual channels (if it has more than 1 channel). 
 Files are stored in subdirectories from a parent directory and per image series directory
*/ 

// Get file and folder information
input_folder = getDirectory("Select a source folder with image file to analyze"); 
fs = File.separator; // This takes the file separator from a given operating system (i.e., "/" or "\") for further use
parent_input_folder = File.getParent(input_folder);
folder_name = File.getNameWithoutExtension(input_folder);
output_folder = parent_input_folder + fs + folder_name + "_output" + fs;
File.makeDirectory(output_folder);

// Get list of proprietary microscopy software files witihn source folder
list1 = getFileList(input_folder);
list2 = newArray(list1.length);
a = 0

/*
 Create a dialog window to store the file extension from user input 
*/
Dialog.create("File extension information");
Dialog.addString('Enter file extension, include the "." (e.g., .lif) ', "");
Dialog.show();
file_extension = Dialog.getString();

// Set batch mode ON/OFF
setBatchMode(true);

/*
 Loop to read files in folder
 */
for(i = 0; i < list1.length; i++){
	if(endsWith(list1[i], file_extension)){  // Change the ".lif" with the specific extension from your software(e.g., "vsi", czi" , etc.)
		list2[a] = list1[i];
		a++;
	}
}
// trim list2
list2 = Array.trim(list2, a);

// Shows elements in list1 (all files in source folder) and elements in list2 (microscopy image files)
//Array.show("Comparison between list1 and list2", list1, list2); // uncomment to see list comparison

/*
 Exports .tif files of merged & max projected image as well as .tif files with individual max projected channels.
*/

// Start batch loop
for(i = 0; i < list2.length; i++){
	
	filepath = input_folder + list2[i]; // Gets path to microscopy data files
	filepath_name = File.getName(filepath);	// Gets filepath fane as string
	subfolder = output_folder + fs + filepath_name + fs;
	File.makeDirectory(subfolder); // Creates a subdirectory with the file name within output_folder to save images from a given file
	
	// Start Bio-Formats Macro Extensions to get series in file(s)
	run("Bio-Formats Macro Extensions");
	Ext.setId(filepath); // Initializes the ginven id (i.e., filename)
	Ext.getSeriesCount(series);
	// Loops through series inside the microscopy image file
	for(j = 0; j < series; j++){
		run("Bio-Formats Importer", "open=["+ filepath +"] autoscale color_mode=Colorized display_metadata rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + (j+1));
		Ext.setSeries(j);
		Ext.openImagePlus(input_folder);
		close("Exception");
		
		// Get file name
		Ext.getSeriesName(series_name);
		NAME = getTitle();
		getDimensions(width, height, channels, slices, frames);
		series_folder = subfolder + fs + series_name + fs;
		File.makeDirectory(series_folder);
		
		// Save as .tif raw series in image file
		selectWindow(NAME);
		saveAs("tiff", series_folder + series_name); // Saves open image as ".tif"

		//
		selectWindow(series_name + ".tif"); // Selects open image (now as ".tif")
		run("Duplicate...", "title=duplicate duplicate");

		// Condition to create Maximum projection
		if(slices > 1){
			run("Z Project...", "projection=[Max Intensity]");
			close("duplicate");
			selectWindow("MAX_duplicate");
			saveAs("tiff", series_folder + "MAX_" + series_name);
			close("MAX_duplicate");
			selectWindow("MAX_" + series_name + ".tif");
			run("RGB Color");
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("jpeg", series_folder + "MAX_RGB_" + series_name);
			close("MAX_MAX_" + series_name + ".tif" + " " + "(RGB)");
			close("MAX_" + series_name + ".tif" + " " + "(RGB)");
		} else {
		}

		// Boolean and Loop to save each channel image
		if(channels > 1){ // Boolean to check if image has more than 1 channel
			selectWindow(series_name + ".tif");
			run("Split Channels");			
		}

		for (k = 0; k < channels; k++){ // Start of the loop
			if(channels == 1){
				channel_name = series_name;
			}
			channel_name = "C" + (k + 1) + "-" + series_name + ".tif";
			selectWindow(channel_name);
			run("Grays");
			saveAs("tiff", series_folder + channel_name);
			run("Z Project...", "projection=[Max Intensity]");
			close(channel_name);
			selectWindow("MAX_" + channel_name);
			saveAs("tiff", series_folder + "MAX_" + channel_name);
			nBins = 256;
			getHistogram(values, counts, nBins); // Gets pixel intensity value and count of individual channel image
			Array.show("Histogram", values, counts); // Shows values and counts in "Results" window with the title "Histogram"
			selectWindow("Histogram");
			saveAs("Text", series_folder + "MAX_" + "C" + (k + 1) + "-" + series_name + "_histogram.csv"); // Save histogram values and counts as .csv
			close("MAX_" + channel_name);
			close("MAX_" + "C" + (k + 1) + "-" + series_name + "_histogram.csv");
		}
		close("MAX_" + series_name + ".tif");
	
		// Save metadata
		selectWindow("Original Metadata - " + filepath_name); // Selects original metadata window
		saveAs("Text", series_folder + series_name + "_metadata.csv"); // Saves as .csv original metadata window as "series_name_metadata.csv" with "series_name" corresponding to the seres name
		selectWindow("Original Metadata - " + filepath_name); // Selects original metadata window
		run("Close"); // Closes "Original Metadata -" window

	}

}

run("Collect Garbage"); // Frees memory
