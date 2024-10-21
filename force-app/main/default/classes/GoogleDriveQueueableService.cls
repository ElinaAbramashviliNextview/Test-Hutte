public with sharing class GoogleDriveQueueableService implements Queueable, Database.AllowsCallouts {
    private static String SVC_NAME = 'SaveDocuSignToGDrive';
    
    public Set<Id> docIds {get;set;}
	public String folderId {get;set;}
	public Id oppId {get;set;}


    public GoogleDriveQueueableService(Id oId, Set<Id> dIds) {
		this.oppId = oId;
        this.docIds = dIds;
		this.folderId = null;
    }
	
	public GoogleDriveQueueableService(Id oId, Set<Id> dIds, String fldrId) {
        this.oppId = oId;
		this.docIds = dIds;
		this.folderId = fldrId;
    }

    public void execute(QueueableContext qc) {
		// If folder id is not set
		if(String.isEmpty(this.folderId)){
			// get opp and parse gdrive folder structure
			Opportunity opp = [SELECT Id, GDriveFolderStructureJSON__c FROM Opportunity WHERE Id =: oppId];
			if(String.isBlank(opp.GDriveFolderStructureJSON__c)){
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 500, 'No g-drive folder structure found, cant upload file.', '' , '');
				return;
			}

			// parse gdrive folder structure
			Mdl.CreateFolderStructureResult gdr = (Mdl.CreateFolderStructureResult)JSON.deserialize(opp.GDriveFolderStructureJSON__c, Mdl.CreateFolderStructureResult.class);
			
			// find google id of Podepsané docu-sign folder, if not found create it
			String folderEID = null;
			Boolean updateOpp = false;
			for(Mdl.DriveFolderInfo dfi : gdr.structure.subfolders){
				if(!dfi.folderName.startsWith('04 Objednavka')){
					continue;
				}

				// if 04 subfolders empty or null create new folder and get eid
				if(dfi.subfolders == null || dfi.subfolders.isEmpty()){
					Mdl.CreateFolderResult signedFolderRes = GoogleDriveService.createFolder('Podepsané docu-sign', dfi.folderId);
					if(!signedFolderRes.isSuccess){
						SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 500, 'Folder "Podepsané docu-sign" not created', '' , '');
					}
					if(dfi.subfolders == null){
						dfi.subfolders = new Mdl.DriveFolderInfo[]{};
					}
					Mdl.DriveFolderInfo newFolder = new Mdl.DriveFolderInfo();
					newFolder.folderName = 'Podepsané docu-sign';
					newFolder.folderId = signedFolderRes.folderID;
					dfi.subfolders.add(newFolder);
					folderEID = signedFolderRes.folderID;
					updateOpp = true;
					SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, 200, 'SUCCESS: #1 folder "'+newFolder.folderName+'" ('+folderEID+') created (OPP ID: '+opp.Id+')');
				}else{  // 04 subfolders not empty, try to find matching folder, else create it
					for(Mdl.DriveFolderInfo sub : dfi.subfolders){
						if(sub.folderName != 'Podepsané docu-sign'){
							continue;
						}else{
							folderEID = sub.folderId;
						}
					}
					// folder not found, create it
					if(folderEID == null){
						Mdl.CreateFolderResult signedFolderRes = GoogleDriveService.createFolder('Podepsané docu-sign', dfi.folderId);
						if(!signedFolderRes.isSuccess){
							SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 500, 'Folder "Podepsané docu-sign" not created', '' , '');
						}
						Mdl.DriveFolderInfo newFolder = new Mdl.DriveFolderInfo();
						newFolder.folderName = 'Podepsané docu-sign';
						newFolder.folderId = signedFolderRes.folderID;
						dfi.subfolders.add(newFolder);
						folderEID = signedFolderRes.folderID;
						updateOpp = true;
						SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, 200, 'SUCCESS: #2 folder "'+newFolder.folderName+'" ('+folderEID+') created (OPP ID: '+opp.Id+')');
					}
				}
			}

			if(updateOpp){
				opp.GDriveFolderStructureJSON__c = JSON.serialize(gdr);
				update opp;
			}
			if(!Test.isRunningTest()){
				System.enqueueJob(new GoogleDriveQueueableService(oppId, docIds, folderEID));
			}
		}else if(!this.docIds.isEmpty()){
			// Create documents on g-drive
			Id lpvId = new List<Id>(this.docIds)[0]; // Content Document LatestPublishedVersionId
			this.docIds.remove(lpvId);
			
			// get content version with data
			ContentVersion cv = [SELECT Id, Title, VersionData, FileType, FileExtension FROM ContentVersion WHERE ID=: lpvId];
			
			// upload file to gdrive
			GoogleDriveService.uploadFileGDrive(cv.Title + '.' + cv.FileExtension, 'application/pdf', this.folderId, EncodingUtil.base64Encode(cv.VersionData));
			if(!this.docIds.isEmpty()){
				System.enqueueJob(new GoogleDriveQueueableService(this.oppId, docIds, this.folderId));
			}
		}
	}
}