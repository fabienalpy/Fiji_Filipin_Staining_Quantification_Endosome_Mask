macro "Fiji_Filipin_Staining_Quantification_Endosome_Mask"{
	
	// File selection 
	FILE_PATH=File.openDialog("Select a .lif file");
	DIR=File.directory;
	FILE=File.name;
	FILEWOEXT=File.nameWithoutExtension;
	OUTPUT_DIR=DIR+FILEWOEXT+File.separator;

	// Variable definition; 
	var SliceNumber=0;
	var FirstSlice=0;
	var NbROI=0;
	var countROI=1;
	var CellNumber=0;

	// Clear ROI Manager function
	function ClearROIM(){
		while( roiManager("count") > 0)
			{		
			roiManager("Select", 0);
			roiManager("Delete");			
			}	
		}
	
	// Log window and Results clearing
	run("Clear Results");
	print("\\Clear");
	
	// Set measurements
	run("Set Measurements...", "area mean min perimeter integrated redirect=None decimal=3");
	
	// File name and directory printing
	print("Chosen File:"+FILE);
	print("File Directory:"+DIR);
	
	// File extension verification
	if ((endsWith(FILE, ".lif")==true) || (endsWith(FILE, ".lei"))){
		print("The file has the correct extension");
		}
	else {
		print("This file is not a .lif file");
		setKeyDown("Esc");
		}

	// Start BioFormats and get series number in file.
	run("Bio-Formats Macro Extensions");
	Ext.setId(FILE_PATH);
	Ext.getSeriesCount(SERIES_COUNT);
	SERIES_NAME=newArray(SERIES_COUNT);
	print("Number of series:"+SERIES_COUNT);
	File.makeDirectory(OUTPUT_DIR);
	
	// Print series number and name.
	for (i=0; i<SERIES_COUNT; i++) {
		i1=i+1;
		Ext.setSeries(i);
		Ext.getSeriesName(SERIES_NAME[i]);
		print("Serie Name["+i1+"]: "+ SERIES_NAME[i]);
		}
		
	// Dialog box
	Dialog.create("Series selection");
	Dialog.addMessage("Choose the images to analyze");
	Dialog.addMessage("(The file list is on the Log window)");
	Dialog.addNumber("From file", 1);
	Dialog.addNumber("To file", SERIES_COUNT);
	Dialog.show();

	// Feeding variables from dialog choices
	IMIN=Dialog.getNumber();
	IMAX=Dialog.getNumber();
	IMIN=IMIN-1;

	// Result File creation
	var StringResults="";
	StringResults= StringResults + "Series Name" + "\t";
	StringResults= StringResults + "Cell Number" + "\t";
	StringResults= StringResults + "Area" + "\t";
	StringResults= StringResults + "Mean" + "\t";
	StringResults= StringResults + "Min" + "\t";
	StringResults= StringResults + "Max" + "\t";
	StringResults= StringResults + "Perim" + "\t";
	StringResults= StringResults + "IntDen" + "\t";
	StringResults= StringResults + "RawIntDen" + "\n";
	IMIN2=IMIN+1;
	OUTPUTTXT=OUTPUT_DIR+"Results_"+IMIN2+"_"+IMAX+".txt";
	File.append (StringResults, OUTPUTTXT);

	var StringResultsMask="";
	StringResultsMask= StringResultsMask + "Series Name" + "\t";
	StringResultsMask= StringResultsMask + "Cell Number" + "\t";
	StringResultsMask= StringResultsMask + "Area" + "\t";
	StringResultsMask= StringResultsMask + "Mean" + "\t";
	StringResultsMask= StringResultsMask + "Min" + "\t";
	StringResultsMask= StringResultsMask + "Max" + "\t";
	StringResultsMask= StringResultsMask + "IntDen" + "\t";
	StringResultsMask= StringResultsMask + "RawIntDen" + "\n";
	IMIN2=IMIN+1;
	OUTPUTTXT2=OUTPUT_DIR+"Results_Mask_"+IMIN2+"_"+IMAX+".txt";
	File.append (StringResultsMask, OUTPUTTXT2);

	// Loop on all series in the .lif file
	for (i=IMIN; i<IMAX; i++) {
		
		// Get series name,channels count, Z count
		Ext.setSeries(i);
		Ext.getEffectiveSizeC(CHANNEL_COUNT);
		Ext.getSizeZ(sizeZ);
		Ext.getSizeC(sizeC);
		SERIES_NAME[i]="";
		Ext.getSeriesName(SERIES_NAME[i]);
		print("Serie Name["+i+"]: "+ SERIES_NAME[i]);
		
		// Import the series
		run("Bio-Formats Importer", "open=["+ FILE_PATH + "] " + "color_mode=Colorized" + " view=Hyperstack " + " stack_order=XYCZT " + "series_"+(i+1));
		run("Stack to Images");
		ClearROIM();

		// Lamp1 mask creation
		selectImage("c:2/"+sizeC+" - "+SERIES_NAME[i]);
		run("Gaussian Blur...", "sigma=1 slice");
		setAutoThreshold("IsoData dark");
		run("Threshold...");
		run("Convert to Mask");
		OUTPUT_PATH=OUTPUT_DIR+SERIES_NAME[i]+"_MaskLamp1"+".tif";
		save(OUTPUT_PATH);

		// Lamp1 mask on filipin image
		imageCalculator("AND create", "c:1/"+sizeC+" - "+SERIES_NAME[i],"c:2/"+sizeC+" - "+SERIES_NAME[i]);
		rename("ResultProcess");
		run("HiLo");
		run("Merge Channels...", "c4=[c:4/"+sizeC+" - "+SERIES_NAME[i]+"] c6=[c:3/"+sizeC+" - "+SERIES_NAME[i]+"] create ignore");
		run("Tile");
		run("Synchronize Windows");

		// ROI selection
		selectWindow("ResultProcess");
		Dialog.create("Number of ROIs");
		Dialog.addNumber("Number of ROIS:", 1);			
		Dialog.show();
		NbROI = Dialog.getNumber();
		setTool("polygon");
		roiManager("Set Color", "yellow");
		roiManager("Set Line Width", 2);
		roiManager("Show All");
		run("Labels...", "color=white font=18 show draw bold");
		if (NbROI > 0){		
			while (countROI < NbROI + 1){
				roiManager("Deselect");
				waitForUser("Draw the ROI (" + countROI + "/" + NbROI + ") and press OK");
				roiManager("Add");
				countROI ++;
				}
			}		
		run("Clear Results");

		// ROI measure
		for (k=0; k<NbROI; k++) {
			roiManager("Select", k);
			run("Measure");
			}
		run("Labels...", "color=white font=36 show draw bold");
		roiManager("Show All with labels");
		run("Flatten");
		OUTPUT_PATH=OUTPUT_DIR+SERIES_NAME[i]+"_FilipinWithMask"+".tif";
		save(OUTPUT_PATH);
		run ("Close All");
		
		// Result writing	
		for (j=0; j<nResults; j++) {
			CellNumber=j+1;
			StringResults= StringResults + SERIES_NAME[i] + "\t";
			StringResults= StringResults + CellNumber + "\t";
			StringResults= StringResults + getResult("Area", j) + "\t";
			StringResults= StringResults + getResult("Mean", j) + "\t";
			StringResults= StringResults + getResult("Min", j) + "\t";
			StringResults= StringResults + getResult("Max", j) + "\t";
			StringResults= StringResults + getResult("Perim.", j) + "\t";
			StringResults= StringResults + getResult("IntDen", j) + "\t";
			StringResults= StringResults + getResult("RawIntDen", j) + "\n";	
			}
		f = File.open(OUTPUTTXT);
		File.append (StringResults, OUTPUTTXT);
		File.close(f);
		run ("Close All");
		run("Clear Results");
		open(OUTPUT_DIR+SERIES_NAME[i]+"_MaskLamp1"+".tif");
		for (k=0; k<NbROI; k++) {
			roiManager("Select", k);
			run("Measure");
			}

		// Results writing	
		for (j=0; j<nResults; j++) {
			CellNumber=j+1;
			StringResultsMask= StringResultsMask + SERIES_NAME[i] + "\t";
			StringResultsMask= StringResultsMask + CellNumber + "\t";
			StringResultsMask= StringResultsMask + getResult("Area", j) + "\t";
			StringResultsMask= StringResultsMask + getResult("Mean", j) + "\t";
			StringResultsMask= StringResultsMask + getResult("Min", j) + "\t";
			StringResultsMask= StringResultsMask + getResult("Max", j) + "\t";
			StringResultsMask= StringResultsMask + getResult("IntDen", j) + "\t";
			StringResultsMask= StringResultsMask + getResult("RawIntDen", j) + "\n";	
			}
		f = File.open(OUTPUTTXT2);
		File.append (StringResultsMask, OUTPUTTXT2);
		File.close(f);
		run("Clear Results");		
		run ("Close All");
		NbROI=0;
		countROI=1;
		ClearROIM();
		  if (isOpen("ROI Manager")) {
    		selectWindow("ROI Manager");
     		run("Close");
			}	
		}	
}






		