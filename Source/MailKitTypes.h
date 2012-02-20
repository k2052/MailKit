#define DEST_CHARSET "UTF-8"
#define MKContentTypesPath @"/System/Library/Frameworks/Foundation.framework/Resources/types.plist"


/* ========================= */
/* = List of Message Flags = */
/* ========================= */

//TODO Turn these into extern's, not defines

#define MKFlagNew			    MAIL_FLAG_NEW
#define MKFlagSeen		    MAIL_FLAG_SEEN
#define MKFlagFlagged	    MAIL_FLAG_FLAGGED
#define MKFlagDeleted		  MAIL_FLAG_DELETED
#define MKFlagAnswered		MAIL_FLAG_ANSWERED
#define MKFlagForwarded		MAIL_FLAG_FORWARDED
#define MKFlagCancelled 	MAIL_FLAG_CANCELLED


/* =========================== */
/* = List of Exception Types = */
/* =========================== */

#define MKMIMEParseError			  @"MIMEParserError"
#define MKMIMEParseErrorDesc		@"An error occured during MIME parsing."

#define MKMIMEUnknownError		    @"MIMEUnknownError"
#define MKMIMEUnknownErrorDesc		@"I don't know how to parse this MIME structure."

#define MKMemoryError	   		    @"MemoryError"
#define MKMemoryErrorDesc  			@"Memory could not be allocated."
                           
#define MKLoginError	   			  @"LoginError"
#define MKLoginErrorDesc   			@"Error logging into account."
                           
#define MKUnknownError	   			@"UnknownError"
                               
#define	MKMessageNotFound		    @"MessageNotFound"
#define	MKMessageNotFoundDesc		@"The message could not be found."

#define	MKNoSubscribedFolders		  @"NoSubcribedFolders"
#define	MKNoSubscribedFoldersDesc	@"There are not any subscribed folders."

#define	MKNoFolders					@"NoFolders"
#define	MKNoFoldersDesc			@"There are not any folders on the server."

#define	MKFetchError				@"FetchError"
#define	MKFetchErrorDesc		@"An error has occurred while fetching from the server."

#define	MKSMTPError					@"SMTPError"
#define	MKSMTPErrorDesc			@"An error has occurred while attempting to send via SMTP."

#define	MKSMTPSocket				@"SMTPSocket"
#define	MKSMTPSocketDesc		@"An error has occurred while attempting to open an SMTP socket connection."

#define	MKSMTPHello					@"SMTPHello"
#define	MKSMTPHelloDesc		  @"An error occured while introducing ourselves to the server with the ehlo, or helo command."

#define	MKSMTPTLS				    @"SMTPTLS"
#define	MKSMTPTLSDesc				@"An error occured while attempting to setup a TLS connection with the server."

#define	MKSMTPLogin					@"SMTPLogin"
#define	MKSMTPLoginDesc		  @"The password or username is invalid."

#define	MKSMTPFrom					@"SMTPFrom"
#define	MKSMTPFromDesc		  @"An error occured while sending the from address."

#define	MKSMTPRecipients			@"SMTPRecipients"
#define	MKSMTPRecipientsDesc	@"An error occured while sending the recipient addresses."

#define	MKSMTPData					@"SMTPData"
#define	MKSMTPDataDesc			@"An error occured while sending message data."

typedef enum 
{
  MKSMTPAsyncSuccess  = 0,
  MKSMTPAsyncCanceled = 1,
  MKSMTPAsyncError    = 2  
} MKSMTPAsyncStatus;