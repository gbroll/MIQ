
fName = getArgument;
//setBatchMode(true);
open(fName);


//Läs in mappen för den aktuella bilden
imageDir = getDirectory("image")

//Läs in ROI-set för imageJ-analysen
strParams = File.openAsString("G:\\MF\\Diagnostik\\autoDQA\\MG\\ImageJ\\imageJparams.txt") 
lines=split(strParams,"\n")
ROIset = split(lines[0],"=")
ROIset = ROIset[1]


//Hämta relevanta parametrar från DICOM-headern
//strTrim tar bort inledande och avslutande blanksteg i strängarna som returneras av getInfo()
//split delar upp sträng för att slänga bort irrelevanta delar

stnName		= strTrim(getInfo("0008,1010"));  					//labID
date			= strTrim(getInfo("0008,0023"));    					//datum
dateXlFormat  = substring(date,0,4) + "-" +	substring(date,4,6) + "-" + substring(date,6,8)	//[YYYYMMDD] -> [YY-MM-DD]

temp			= split(getInfo("0008,0033"),".");  	//tid på formatet hhmmss.xxxx; släng bort ".xxxx",
time			= strTrim(temp[0]);					
timeXlFormat	= substring(time,0,2) + ":" +	substring(time,2,4) + ":" + substring(time,4,6)	//[hhmmss] -> [hh:mm:ss]

imgType     	= strTrim(getInfo("0008,0068"));  					//ska vara "FOR PROCESSING"

kVp			= parseFloat(strTrim(getInfo("0018,0060")));  			//rörspänning [kV]
mAs			= parseFloat(strTrim(getInfo("0018,1153")))/1000;  		//rörladdning [uAs]->[mAs]
focSize		= parseFloat(strTrim(getInfo("0018,1190")));  			//fokusstorlek [mm]
anMat		= strTrim(getInfo("0018,1191"));  					//anodmaterial
bpThick		= strTrim(getInfo("0018,11A0"));  					//tjocklek [mm]
cmpForce		= strTrim(getInfo("0018,11A2"));  					//kompressionskraft[Newton]
fltMat		= strTrim(getInfo("0018,7050"));  					//filtermaterial
ecm			= strTrim(getInfo("0018,7060")); 						//exponeringsteknik (auto eller manuell)
ecmDesc		= strTrim(getInfo("0018,7062"));  					//beskrivning för ecm, ska stå "AOP dose" i strängen
temp 		= split(ecmDesc," ");								//spara bara de första två orden i strängen
ecmDesc		= temp[0]	+ " "+ temp[1]						


orgDose		= parseFloat(strTrim(getInfo("0040,0316")))*100; 		//"organdos"[dGy]->[mGy] (!)
entDose		= parseFloat(strTrim(getInfo("0040,8302")));  			//ingångsdos [mGy]




//Läs in ROI-fil, ta bort eventuella ROIs först om sådana finns
nOldRois = roiManager("count");
if (nOldRois>0){
	indexes = newArray(nOldRois);
	for (i=0; i<nOldRois;i++){
      indexes[i] = i;
	}
roiManager("Select",indexes);
roiManager("Delete");
}

roiManager("Open", ROIset);
roiManager("Show all");



//deklarera variabler för att spara mätresultat
nRoi = roiManager("count");  //antalet ROI
meanArr = newArray(nRoi); 	//medelvärden i respektive ROI
stdArr  = newArray(nRoi); 	//standardavvikelse i respektive ROI


//Loopa igenom alla ROIar och mät
for (i = 0; i <roiManager("count");i++){
	roiManager("select", i);
	Roi.setStrokeWidth(7); 	//sätt linjetjocklek på ROI
	Roi.setStrokeColor("red") ;	//sätt linjefärg på ROI
	getRawStatistics(nPixels, mean, min, max, std);
	meanArr[i] = mean;
	stdArr[i]  = std;
}

//Spara resultat i textfil för inläsning i Excel
resFile = File.open(imageDir + stnName + "_" + date + "_" + time +".txt");
dummy = printResultsToTextFile(resFile, stnName, date, time, meanArr, stdArr);
File.close(resFile);

//döp om DICOM-filen enligt stationname_datum_tid för att matcha övrig namngivning
dummy = File.rename(imageDir + File.name,imageDir + stnName + "_" + date + "_" + time + ".dcm");
print(imageDir + File.name);
print(dummy);


//spara bild (med ROIar) som JPEG, filnamn som stationname_datum_tid
selectImage(1);
run("Enhance Contrast", "saturated=0.35");
run("Line Width...", "line=5");
run("From ROI Manager");
saveAs("jpeg",imageDir + stnName + "_" + date + "_" + time + ".jpg");


//avsluta imageJ
//run("Quit");


function printResultsToTextFile(resFile, stnName, date, time, meanArr, stdArr){

	print(resFile,stnName);
	print(resFile,dateXlFormat);
	print(resFile,timeXlFormat);
	
	//print(resFile," ");
	
	//skriv ut önskade dicom-parametrar
	print(resFile,orgDose);
	print(resFile,entDose);	
	print(resFile,mAs);
	print(resFile,kVp);
	print(resFile,focSize);
	print(resFile,anMat);
	print(resFile,fltMat);
	print(resFile,bpThick);
	print(resFile,cmpForce);
	print(resFile,ecm);
	print(resFile,ecmDesc);
	print(resFile,imgType);
	
	

	//skriv ut medelvärde och resultat, kommaseparerat, ett ROI per rad
	for (i = 0; i <lengthOf(meanArr);i++){
		print(resFile,meanArr[i]+", "+stdArr[i]);
		
	}

	

	return 1;
}


function strTrim(strIn){

	strIn = replace(strIn, "\\s*$", ""); //removes trailing whitespaces 
	strIn = replace(strIn, "^\\s*", ""); //removes leading whitespaces 

	return strIn;

}



