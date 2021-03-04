//UNIFORMITY ANALYSIS OF DAILY QC IMAGES USING CO57 Flood Images

targetPixSize	= 6.4;   						 	//set target pixel size
thLvl	   	= 0.80;								//threshold for finding UFOV (fraction of max)
NEMAthLvl	= 0.75;								//threshold for pixels to exclude

//---------------------------------------------------------------------------------------------------------------------------

//DECLARE VARIABLES (global scope for programming with functions)

var fName			= "";
var fileList  		= newArray();
var path 			= "";
var nFiles		= 0;
var nDetectors		= 0;

var studyUID 		= "";
var resFileStr		= "";
var resultStr		= "";


var date			= "";
var dateXlFormat 	= "";
var time 			= "";
var timeXlFormat 	= "";
var stnName		= "";
var seriesDesc		= "";
var acqTime		= 0.0;
var eWinLow		= 0.0;
var eWinHigh		= 0.0;
var cllmtr		= "";
var nCounts		= 0.0;
var pixSize		= 0.0;
var mtxSizeX		= 0.0;
var mtxSizeY		= 0.0;

var rebinFactor = 0;
var newMtxSizeX = 0.0;
var newMtxSizeY = 0.0;
var newPixSize  = 0.0;

var startX = 0;
var startY = 0;
var stopX  = 0;
var stopY  = 0;

var excludePixelsX = newArray();
var excludePixelsY = newArray();

var IU_UFOV = 0;
var IU_CFOV = 0;

var DU_X_UFOV = 0;
var DU_X_CFOV = 0;

var DU_Y_UFOV = 0;
var DU_Y_CFOV = 0;

var UFOVsize = newArray(2);
var CFOVsize = newArray(2);

var UFOVlow    = 0;
var UFOVhigh   = 0;
var UFOVlowX   = 0;
var UFOVlowY   = 0;
var UFOVhighX  = 0;
var UFOVhighY  = 0;

var CFOVlow	= 0;
var CFOVhigh	= 0;
var CFOVmean	= 0;
var CFOVstd	= 0;

var UFOVmean = 0;
var UFOVstd  = 0;

var lowCount	= 0;
var highCount	= 0;
var lowX 	= 0;
var lowY 	= 0;
var highX 	= 0;
var highY 	= 0;

var roiWidth	= 0;
var roiHeight	= 0;
var roiIU 	= 0;
var roiDUx	= 0;
var roiDUy	= 0;
var roiMax	= 0;
var roiMin 	= 0;
var roiMean 	= 0;
var roiStd 	= 0;

//--------------------------------------------------------------------------------------------------------------------------

// MAIN PROGRAM START

args			= getArgument();  				//get the arguments from the batch file
splitArgs		= split(args,",");				//split argument string

path			= splitArgs[0];				//file name of the last file sent before executing the script
nDetectors 	= parseInt(splitArgs[1]);		//number of detectors for the camera
nFiles		= parseInt(splitArgs[2]);		//number of DICOM files sent before executing the script

dummy = getFiles();							//get the list of associated files in the directory

for (i=0; i<nDetectors; i++){
	
	dummy	= openImage(i,nFiles);			//open the image

	dummy 	= extractDicom();				//extract the relevant information from the DICOM header

	dummy 	= preProImage();				//convert to 32-bit unsigned

	dummy 	= rebinImage();				//rebin the image to the target pixel size (approx to keep integer rebinning factor)

	dummy 	= setUFOVandCFOV();				//set an initial UFOV and CFOV

	//dummy 	= excludePixels();				//exclude edge pixels (by setting to zero) accordning to NEMA  !!!removed 2016-02-26 due to problems with UFOV when pixels are set to zero since getRawSatistics() is used

	dummy 	= setUFOVandCFOV();				//adjust the FOV and CFOV after exclusion of the edge pixels

	dummy 	= adaptiveFilter(); 			//perform "convolution" with 9-pts smoothing kernel but exclude all zero pixels

	dummy 	= calculateUFOVparams();		//calculate UFOV parameters

	dummy 	= calculateCFOVparams();		//calculate CFOV parameters

	dummy 	= printResultsToFile(i);		//print the results to file

	dummy 	= writeJPEG(i);				//generate a nice summary screenshot

	dummy	= closeWindows();				//close all opened images and other windows

}

dummy	= renameDicom();					//rename DICOM files prior to archiving

run("Quit");								//exit imageJ

//---------------------------------------------------------------------------------------------------------------------------

function getFiles(){

	
	//path = getInfo("image.directory");		//save the path to the file
		
	fileList = getFileList(path);               //search for files in the current directory and check their study UIDs
	
            print(path);
	print(fileList[0]);

	dcmFileList = newArray();
	for (i=0; i<(lengthOf(fileList)); i++){
		if (isDicom(fileList[i])){
			dcmFileList = Array.concat(dcmFileList,fileList[i]);
		}
	}

	open(path + dcmFileList[0]);    				//open the first file
	rename("org");							//rename file for reference
	studyUID = strTrim(getInfo("0020,000D"));	//get the study UID
		
	assFiles = newArray();
	for (i=0; i<(lengthOf(dcmFileList)); i++){
		print(path+dcmFileList[i]);
		open(path+dcmFileList[i]);
		thisStudyUID = strTrim(getInfo("0020,000D"));
		if (thisStudyUID==studyUID){
			assFiles = Array.concat(assFiles,dcmFileList[i]);
		}
		close();
	}

	fileList = assFiles;

	selectImage("org");
	close();
	return 1;

}

//---------------------------------------------------------------------------------------------------------------------------
function openImage(fileIndex,nFiles){

	//This function opens the images
	//If there are images for >1 detector in the same file, deal with it here	

	open(path+fileList[fileIndex]);
	rename("Raw");
	return 1;
}

//---------------------------------------------------------------------------------------------------------------------------

function closeWindows(){

	//This function should close all opened windows and images
	
	list = getList("window.titles"); 
     for (i=0; i<list.length; i++){ 
     	winName = list[i]; 
     	selectWindow(winName);
		print(winName); 
     	if (winName!="NM_DQA.ijm") run("Close"); 
     } 

	list = getList("image.titles");
     for (i=0; i<list.length; i++){ 
     	imgName = list[i]; 
     	selectImage(imgName);
		print(imgName); 
     	if (imgName!="Summary") run("Close"); 
     } 

	return 1;

}

//---------------------------------------------------------------------------------------------------------------------------
function extractDicom(){

//EXTRACT DICOM information

	date 		= strTrim(getInfo("0008,0023"));        				//Image Date
	dateXlFormat	= substring(date,0,4) + "-" +	
				  substring(date,4,6) + "-" + substring(date,6,8);		//[YYYYMMDD] -> [YY-MM-DD]
	temp			= split(getInfo("0008,0033"),".");  					//tid på  formatet hhmmss.xxxx; släng bort ".xxxx",
	time			= strTrim(temp[0]);					
	timeXlFormat	= substring(time,0,2) + ":" +	
				  substring(time,2,4) + ":" + substring(time,4,6);		//[hhmmss] -> [hh:mm:ss]

	stnName		= strTrim(getInfo("0008,1010"));      					//Station Name
	seriesDesc 	= strTrim(getInfo("0008,103E"));						//Series Description (head1 or head2 for the VG camera)
	acqTime 		= getNumericTag("0018,1242")/1000;					//Acquisition Time [ms] -> [s]
	eWinLow 		= getNumericTag("0054,0014");						//Lower limit Energy Window
	eWinHigh		= getNumericTag("0054,0015");        					//Upper limit Energy Window
	cllmtr		= strTrim(getTag("0018,1180"));	       				//Collimator name
	nCounts 		= getNumericTag("0018,0070");						//Number of counts accumulated

	pixSize     	= getNumericTag("0028,0030");						//get the pixel size
	mtxSizeX    	= getNumericTag("0028,0010");						//get the number of columns
	mtxSizeY    	= getNumericTag("0028,0011");						//get the number of rows

	return 1;

}

//--------------------------------------------------------------------------------------------------------------------------

function preProImage(){

//Image preprocessing (convert to 32-bit unsigned)

	calA = calibrate(0);
	calB = calibrate(1)-calibrate(0);
	for (i=0; i<mtxSizeX; i++){
		for (j=0;j<mtxSizeY; j++){
  		   	val = getPixel(i,j)*calB+calA;	
			setPixel(i,j,val);
		}
	}	

	run("Calibrate...", "function=[Straight Line] unit=[Gray Value] text1=[0 1 ] text2=[0 1]");
	run("32-bit");	

	return 1;

}

//--------------------------------------------------------------------------------------------------------------------------

function rebinImage(){

//This function rebins the image using the built-in ImageJ functions. The rebinning has been validated against 
//manual rebinning. Only integer rebinning is allowed
		
	rebinFactor = targetPixSize/pixSize;
	newMtxSizeX = round(mtxSizeX/rebinFactor);
	newMtxSizeY = round(mtxSizeY/rebinFactor);
	newPixSize  = mtxSizeX/newMtxSizeX*pixSize;

	countScaleFactor = rebinFactor*rebinFactor;	

	selectImage("Raw");
	run("Scale...", "x=- y=- width=" + 
	d2s(newMtxSizeX,0) + " height=" + d2s(newMtxSizeY,0) + 
	" interpolation=None average create title=Rebinned");
	
	run("Multiply...", "value=" + d2s(countScaleFactor,8));

	return 1;	

}

//--------------------------------------------------------------------------------------------------------------------------

function setUFOVandCFOV(){

//This function finds and set an approximate UFOV and CFOV
	
	selectImage("Rebinned");
	
	//remove all old ROIs
	dummy = removeROIs();

	//sum vertical profiles
	vertSums = newArray();
	temp = 0;
	for (i=0; i<newMtxSizeX; i++) {
		makeLine(i, 0, i, newMtxSizeY , 1);
		qqq = getProfile();	
		temp1 = sumArray(qqq);
		vertSums = Array.concat(vertSums,temp1);
		if (temp1>temp) temp = temp1;
	}
	maxVert = temp;

	//sum horizontal profiles
	hrSums = newArray();
	for (i=0; i<newMtxSizeY; i++) {
		makeLine(0, i, newMtxSizeY,i, 1);
		qqq = getProfile();	
		temp1 = sumArray(qqq);
		hrSums = Array.concat(hrSums,temp1);
		if (temp1>temp) temp = temp1;
	}
	maxHor = temp;

	//loop through verticals and find start and stop indexes
	startX = 0;
	stopX  = newMtxSizeX;
	for (i=0; i<newMtxSizeX; i++) {	
		if ((startX==0) && (vertSums[i]>thLvl*maxVert)){
			startX = i+1;
		}	
		if ((i>(newMtxSizeX/2)) && (vertSums[i]<(thLvl*maxVert))){
			if (stopX==newMtxSizeX) stopX = i-1;	
		}
	}

	//loop through horizontals and find start and stop indexes
	startY = 0;
	stopY  = newMtxSizeY;
	for (i=0; i<newMtxSizeY; i++) {
		if ((startY==0) && (hrSums[i]>thLvl*maxHor)){
			startY = i+1;
		}	
		if ((i>(newMtxSizeY/2)) && (hrSums[i]<(thLvl*maxHor))){
			if (stopY==newMtxSizeY) stopY = i-1;
		}

	}

	//set UFOV and CFOV
	makeRectangle(startX,startY,stopX-startX,stopY-startY);
	roiManager("Add")
	run("Clear Outside");
	makeRectangle(startX+(0.125*(stopX-startX)),startY+(0.125*(stopY-startY)),0.75*(stopX-startX),0.75*(stopY-startY));
	roiManager("Add")
	//wait(10000);
	getRawStatistics(CFOVnPixels,CFOVmean,CFOVmin, CFOVmax, CFOVstd, CFOVhistogram);

	return 1;
}

//-----------------------------------------------------------------------------------------------------------------------------

function excludePixels(){
	
//This functions sets pixels in the edges of the FOV to zero for subsequent exclusion in the analysis according to NEMA
	
	start = startX-1;
	stop = stopX-1;
	columns = newArray(start,stop);
	for (i=0;i<2;i++){
		x = columns[i];
		for (y=(startY-1); y<(stopY+1); y++) {
			if (getPixel(x,y)<(NEMAthLvl*CFOVmean)) {
				excludePixelsX = Array.concat(excludePixelsX,x);
				excludePixelsY = Array.concat(excludePixelsY,y);
				setPixel(x,y,0);
			}
		}
	}

	start = startY-1;
	stop = stopY;
	rows= newArray(start,stop);
	for (i=0;i<2;i++){
		y = rows[i];
		for (x=(startX-1); x<(stopX+1); x++) {
			if (getPixel(x,y)<(NEMAthLvl*CFOVmean)) {	
				excludePixelsX = Array.concat(excludePixelsX,x);
				excludePixelsY = Array.concat(excludePixelsY,y);
				setPixel(x,y,0);
			}
		}
	}
	
	for (i=0; i<newMtxSizeX; i++) {
     	for (j=0; j<newMtxSizeY; j++){
		
			n1 = getPixel((i-1),j);
			n2 = getPixel((i+1),j);
			n3 = getPixel(i,(j-1));
			n4 = getPixel(i,(j+1));

			if (i==0) 			n1 = 1;
			if (i==newMtxSizeX) 	n2 = 1;
			if (j==0) 			n3 = 1;
			if (j==newMtxSizeY) 	n4 = 1;
		
			prod = n1/CFOVmean*n2/CFOVmean*n3/CFOVmean*n4/CFOVmean;
			//print(prod);
			if (prod<0.00001) {
				//print(d2s(i,0) + ","+d2s(j,0));
				excludePixelsX = Array.concat(excludePixelsX,i);
				excludePixelsY = Array.concat(excludePixelsY,j);
			}
		}
   	}

	for (i=0; i<lengthOf(excludePixelsX); i++) {
		setPixel(excludePixelsX[i],excludePixelsY[i],0);
	}

	return 1;
}

//--------------------------------------------------------------------------------------------------------------------------

function adjustUFOVandCFOV(){



}


function adaptiveFilter(){
	
	newPixelValues = newArray(newMtxSizeX *newMtxSizeY);

	for (i=0; i<newMtxSizeX; i++) {
		for (j=0; j<newMtxSizeY; j++){
			newVal = 0;
			nn = 1;
			n1 = getPixel(i-1,j-1);
			n2 = getPixel(i,j-1);
			n3 = getPixel(i+1,j-1);
			n4 = getPixel(i-1,j);
			n5 = getPixel(i,j);
			n6 = getPixel(i+1,j);
			n7 = getPixel(i-1,j+1);
			n8 = getPixel(i,j+1);
			n9 = getPixel(i+1,j+1);
			if (n5>0){
				newVal = n5*4;
				nn     = 4;

				if (n1>0){
					newVal = newVal+n1*1;
					nn = nn+1;
				}
				if (n2>0){
					newVal = newVal+n2*2;
					nn = nn+2;
				}
				if (n3>0){
					newVal = newVal+n3*1;
					nn = nn+1;
				}
				if (n4>0){
					newVal = newVal+n4*2;
					nn = nn+2;
				}
				if (n6>0){
					newVal = newVal+n6*2;
					nn = nn+2;
				}
				if (n7>0){
					newVal = newVal+n7*1;
					nn = nn+1;
				}
				if (n8>0){
					newVal = newVal+n8*2;
					nn = nn+2;
				}
				if (n9>0){
					newVal = newVal+n9*1;
					nn = nn+1;
				}
				
				newPixelValues [i+j*newMtxSizeX] = newVal/nn;

			}
		}
	}

		for (i=0; i<newMtxSizeX; i++) {
     		for (j=0; j<newMtxSizeY; j++){
			setPixel(i,j,newPixelValues [i+j*newMtxSizeX]);	
			}
		}

	return 1 ;

}

//--------------------------------------------------------------------------------------------------------------------------

function calculateUFOVparams(){

//This function calculates the parameters of interest for the UFOV
	
	dummy = calcParams(0);

	UFOVsize[0] 	= roiWidth;
	UFOVsize[1] 	= roiHeight;
	IU_UFOV 		= roiIU;
	DU_X_UFOV 	= roiDUx;
	DU_Y_UFOV		= roiDUy;

	UFOVlow    = lowCount;
	UFOVhigh   = highCount;
	UFOVlowX   = lowX;
	UFOVlowY   = lowY;
	UFOVhighX  = highX;
	UFOVhighY  = highY;

	UFOVmean		= roiMean;
	UFOVstd		= roiStd;

	return 1;
}

//--------------------------------------------------------------------------------------------------------------------------

function calculateCFOVparams(){

//This function calculates the parameters of interest for the CFOV
	
	dummy = calcParams(1);

	CFOVsize[0] 	= roiWidth;
	CFOVsize[1] 	= roiHeight;
	IU_CFOV 		= roiIU;
	DU_X_CFOV 	= roiDUx;
	DU_Y_CFOV		= roiDUy;

	CFOVlow    = lowCount;
	CFOVhigh   = highCount;
	
	CFOVmean		= roiMean;
	CFOVstd		= roiStd;

	return 1;
}

//--------------------------------------------------------------------------------------------------------------------------

function calcParams(roiIndex){
	
	roiManager("select", roiIndex); //the second ROI is the final CFOV
	getRawStatistics(roiNPixels, roiMean, roiMin, roiMax, roiStd, roiHist);
	Roi.getBounds(x, y, roiWidth , roiHeight);

	roiIU = (roiMax-roiMin)/(roiMax+roiMin);
	roiWidth = roiWidth * newPixSize;
	roiHeight = roiHeight * newPixSize;

	dummy = diffUni(roiIndex);
	
	maxVal = 0;
	minVal = 1000000;


	for (i = 0;i<newMtxSizeX;i++){
		for (j=0;j<newMtxSizeY;j++){
		
			if (Roi.contains(i, j)>0){
			
				newVal = getPixel(i,j);
				if (newVal>maxVal){
					maxVal = newVal;
					highX = i;
					highY = j;
					//print(maxVal);
				}
				if (newVal<minVal){
					minVal = newVal;
					lowX = i;
					lowY = j;
					//print(minVal);
				}
			}
		

		}
	}

	lowCount	= minVal;
	highCount	= maxVal;

	return 1;

//--------------------------------------------------------------------------------------------------------------------------

function diffUni(roiIndex){

//This function calculates the differential uniformity accordning to NEMA for the specified ROI (roiIndex)

	roiManager("Select", roiIndex);

	if (roiIndex==0) title="UFOV";
	if (roiIndex==1) title="CFOV";

	run("Duplicate...", "title="+title);

	//rows
	roiDUx = 0;
	for (r=0; r<getHeight();r++){
		for (i=0; i<(getWidth()-4); i++){
			max = 0;
			min = 10000000;
			for (j=0; j<5; j++){
				val = getPixel(i+j,r);
			
				if (val<min) min = val;
				if (val>max) max = val;
		
			}
			temp = (max-min)/(max+min);
			if (temp>roiDUx) roiDUx = temp;
		}
	}

	//columns
	roiDUy = 0;
	for (r=0; r<getWidth();r++){
		for (i=0; i<(getHeight()-4); i++){
			max = 0;
			min = 10000000;
			for (j=0; j<5; j++){
				val = getPixel(r,i+j);
				//print(d2s(r,0)+","+d2s(i+j,0));
				if (val<min) min = val;
				if (val>max) max = val;
			}
			temp = (max-min)/(max+min);
			if (temp>roiDUy) roiDUy = temp;
		}
	}

	close();

	return 1;

}

//--------------------------------------------------------------------------------------------------------------------------

function printResultsToFile(detectorIndex){

	//This functions prints the results 

	if (detectorIndex==(0)){

		resultStr = resultStr + stnName 		+ "\r\n";
		resultStr = resultStr + dateXlFormat	+ "\r\n";
		resultStr = resultStr + timeXlFormat	+ "\r\n";
		resultStr = resultStr + cllmtr		+ "\r\n";
		resultStr = resultStr + eWinLow		+ "\r\n";
		resultStr = resultStr + eWinHigh		+ "\r\n";
	}
	
	resultStr = resultStr  + "\r\n";
	resultStr = resultStr + "Detector "+d2s(detectorIndex+1,0)	+ "\r\n";
	resultStr = resultStr  + seriesDesc + "\r\n";
	resultStr = resultStr + d2s(nCounts,0)		+ "\r\n";
	resultStr = resultStr + d2s(acqTime,2) + "\r\n";
	resultStr = resultStr + d2s(newPixSize,3) + "\r\n";
	resultStr = resultStr + d2s(UFOVsize[0],0) + "," + d2s(UFOVsize[1],0) + "\r\n";
	resultStr = resultStr + d2s(UFOVlow,0) + "," + d2s(UFOVhigh,0) + "\r\n";
	resultStr = resultStr + d2s(UFOVmean,3) + "," + d2s(UFOVstd,3) + "\r\n";
	resultStr = resultStr + d2s(IU_UFOV,5) + "\r\n";
	resultStr = resultStr + d2s(DU_X_UFOV,5) + "\r\n";
	resultStr = resultStr + d2s(DU_Y_UFOV,5) + "\r\n";
	
	resultStr = resultStr + d2s(CFOVsize[0],0) + "," + d2s(CFOVsize[1],0) + "\r\n";
	resultStr = resultStr + d2s(CFOVlow,0) + "," + d2s(CFOVhigh,0) + "\r\n";
	resultStr = resultStr + d2s(CFOVmean,3) + "," + d2s(CFOVstd,3) + "\r\n";
	resultStr = resultStr + d2s(IU_CFOV,5) + "\r\n";
	resultStr = resultStr + d2s(DU_X_CFOV,5) + "\r\n";
	resultStr = resultStr + d2s(DU_Y_CFOV,5) + "\r\n";


	if (detectorIndex==(nDetectors-1)){

		resFileStr = path+stnName+"_"+date+"_"+time+".txt";	
		resFile = File.open(resFileStr);
		print(resFile,resultStr);
		File.close(resFile);
	}


	return 1;

}

//--------------------------------------------------------------------------------------------------------------------------

function writeJPEG(detectorIndex){

	//This function is supposed to generate a nice JPEG with a result summary
	//Settings are changed here:

	scale 	= 3;
	margin 	= 20;
	yMargin 	= 20;
	yOffset 	= 40;	
	imgSize  	= 320;

	yPos		= yMargin*(detectorIndex+1)+(imgSize  *detectorIndex)+yOffset;
	
	if (detectorIndex==0) newImage("Summary", "32-bit black", (margin*4)+imgSize  *3, (imgSize  +yMargin*3)*nDetectors+yOffset, 1);		//Create summary screen
	
	imageList = newArray("Raw","Rebinned","Rebinned");

	for (i=0;i<3;i++){
	
		xPos		= margin * (i+1) + (imgSize  *i);
		print(xPos);

		selectImage(imageList[i]);
		orgW = getWidth();
		orgH	= getHeight();		

		run("Select All");
		
		if (i==2){
			roiManager("Select", 0);
		} else {
			roiManager("Deselect");
			run("Select All");
		}
		run("Enhance Contrast", "saturated=0.35");
		run("Select All");
		run("Scale...", "x=- y=- width="+d2s(imgSize,0)+" height="+d2s(imgSize,0)+" interpolation=None average create title=Copy");
	
		selectImage("Summary");
		run("Add Image...", "image=Copy x="+d2s(xPos,0)+" y="+d2s(yPos,0)+" opacity=100");

		//add UFOV and CFOV as overlays
		
		for (j=0;j<2;j++){
			roiManager("Select",j);
			Roi.getBounds(x, y, width, height);
			if (i==0){
				newPosX	= xPos+x*imgSize/orgW*newPixSize/pixSize;
				newPosY	= yPos+y*imgSize/orgH*newPixSize/pixSize;
				newWidth	= imgSize/orgW*width*newPixSize/pixSize;
				newHeight	= imgSize/orgW*height*newPixSize/pixSize;
			} else {
				newPosX	= xPos+x*imgSize/orgW;
				newPosY	= yPos+y*imgSize/orgH;
				newWidth	= imgSize/orgW*width;
				newHeight	= imgSize/orgW*height;
			}
		
			run("Specify...", "width="+d2s(newWidth,0)+" height="+d2s(newHeight,0)+" x="+d2s(newPosX,0)+" y="+d2s(newPosY,0));
			roiManager("Add");
			roiManager("Set Line Width", 2);
			Overlay.addSelection;		
		}

		selectImage("Copy");
		close();	

	}
		
	//make some annotations
	
	if (detectorIndex>0)  Overlay.paste;	

	setFont("SanSerif", 18,"bold");
	setColor("white");
	Overlay.drawString("Detector "+d2s(detectorIndex+1,0)+": "+seriesDesc,margin+10,yPos);
	
	if (detectorIndex<nDetectors-1)  Overlay.copy;


	if (detectorIndex==nDetectors-1) {
		
		titles = newArray("Raw","Processed (Linear)","Processed (Contrast)");
		setFont("SanSerif", 16,"bold");
		for (i=0;i<3;i++){
			
			xPos	= margin * (i+1) + (imgSize  *i); 	
			Overlay.drawString(titles[i],xPos+margin,yPos+imgSize+margin);

		}		
		Overlay.show;
		run("Select None");
		selectImage("Summary");
		saveAs("jpeg",path+ stnName + "_" + date + "_" + time + ".jpg");
	}
	
	return 1;

}

//--------------------------------------------------------------------------------------------------------------------------

function renameDicom(){

//This function renames the DICOM files (by copy and delete)

	for (i=0;i<(nFiles);i++){
		newFileName = stnName + "_" + date + "_" + time;
		if (nFiles>1){
			newFileName = newFileName + "_" + d2s(i,0);		
		}
		newFileName = newFileName+".dcm";
		File.copy(path+fileList[i], path+newFileName); 
		File.delete(path+fileList[i]);
	}

	return 1;

}

//---------------------------- UTILITY FUNCTIONS //-------------------------------------------------------------------------

function strTrim(strIn){

	strIn = replace(strIn, "\\s*$", ""); //removes trailing whitespaces 
	strIn = replace(strIn, "^\\s*", ""); //removes leading whitespaces 

	return strIn;

}

function getNumericTag(tag) {

// This function returns the numeric value of the 
// specified tag (e.g., "0018,0050"). Returns NaN 
// (not-a-number) if the tag is not found or it 
// does not have a numeric value.

    value = getTag(tag);
    if (value=="") return NaN;
    index3 = indexOf(value, "\\");
    if (index3>0)
      value = substring(value, 0, index3);
    value = 0 + value; // convert to number
    return value;
}


function getTag(tag) {

// This function returns the value of the specified 
// tag  (e.g., "0010,0010") as a string. Returns "" 
// if the tag is not found.

      info = getImageInfo();
      index1 = indexOf(info, tag);
      if (index1==-1) return "";
      index1 = indexOf(info, ":", index1);
      if (index1==-1) return "";
      index2 = indexOf(info, "\n", index1);
      value = substring(info, index1+1, index2);
      return value;
}

function sumArray(arrIn){

	sum = 0;
	for (i=0; i<lengthOf(arrIn); i++){
		sum = sum + arrIn[i];
	}
	return sum;
}

function removeROIs(){
	
//Remove ROIs if any exists

	nOldRois = roiManager("count");
	if (nOldRois>0){
		indexes = newArray(nOldRois);
		for (i=0; i<nOldRois;i++){
      		indexes[i] = i;
		}

	roiManager("Select",indexes);
	roiManager("Delete");

	}

	return 1;
}

function isDicom(filename) {

	extensions = newArray("dcm");
	result = false;
	for (i=0; i<extensions.length; i++) {
		if (endsWith(toLowerCase(filename), "." + extensions[i]))
			result = true;

	}
	return result;
}

//--------------------------------------------------------------------------------------------------------------------------



