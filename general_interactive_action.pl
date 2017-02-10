# $language = "PerlScript"
# $interface = "1.0"

#use threads;
#use threads::shared;

use Win32::OLE;
Win32::OLE->Option(Warn => 3);
use 5.010;
our $true=1;
our $false=0;
$crt->Screen->{'Synchronous'} = $false;

#my $thr1=threads->create(\&AutoComand,$crt);
#my $thr2=threads->create(\&general_interactive_action,$crt);

#our @allthreads=threads->list(threads::all);
#$mydialog->MessageBox("@allthreads");

#$thr1->detach();
#$thr2->detach();

#$thr1->join();
#$thr2->join();

my $decison = 
    $crt->Dialog->Prompt("trigger command or period command  [TP]?");

if ( $decison =~ /[pP]/ ) {
    my $decison2 = 
        $crt->Dialog->Prompt("SingleTab or MultiTab [SM]?");
    if ( $decison2 =~ /[sS]/) {
        &AutoComand;
    }
    else {
        &autocomandmultitab;
    }
}
else {
    &general_interactive_action;
}

#our @allrunningthreads=threads->list(threads::joinable);

#$mydialog->MessageBox("all threads are @allthreads");
#$mydialog->MessageBox("all running threads are @allrunningthreads");
$SIG{'TERM'}=$SIG{'INT'}=\&terminate;

sub terminate {
#    print "Get your Ctrl+C byebye! exit .. \n";
    exit 0;
}


sub autocomandmultitab {
        my $myscreen =$crt->Screen;
        my $mydialog =$crt->Dialog;
        my $TabCount =$crt->GetTabCount;
        $mydialog->MessageBox("the \$TabCount is $TabCount");
        $myscreen->{'Synchronous'} = $true;
        my @objTab;
        foreach ( 1..$TabCount ) {
            $objTab[$_-1] = $crt->GetTab($_);
        }
        my $CommandInterval = $mydialog->Prompt("Please assign timer Interval for each command");
        $CommandInterval=1 unless ($CommandInterval);
        $mydialog->MessageBox("the CommandInterval is $CommandInterval second");

        my $TimeIntervalForCommandGroup = $mydialog->Prompt("Please assign the timer Interval for command group");
        $TimeIntervalForCommandGroup=90 unless ($TimeIntervalForCommandGroup);
        $mydialog->MessageBox("the Command Group Interval is $TimeIntervalForCommandGroup second");

        my $MaxTimes = $mydialog->Prompt("Please assign MaxTimes for Command Group");
        $MaxTimes=10 unless ($MaxTimes);
        $mydialog->MessageBox("the MaxTimes is $MaxTimes");

        my $Commands = $mydialog->Prompt("Please input commands seperated by ',' ");
        if ($Commands) {
            our @Commands = split /,/,$Commands;
        }
        else {
            @Commands=( '{date(),time(),ets:tab2list(plcInfo),plcScheduler:plc_res(3,1000),agsaSippy:count()}.' );
        }
            $mydialog->MessageBox("the Command is @Commands");
            #our $realreport = $mydialog->Prompt("Alarm report RealTime ? 1 TO YES, 0 TO NO");
            #$realreport = 1 unless ($RealReport);
            $realreport = 0;
            our @Tabgroup = split /-/, $mydialog->Prompt("Please assign start tab and end tab number: 1-3 i.e. ");
                @Tabgroup=(1,$TabCount) unless (@Tabgroup);
            our @MonitorTabGroup = @objTab[ $Tabgroup[0]-1 .. $Tabgroup[-1]-1 ];
            $mydialog->MessageBox("tab $Tabgroup[0]~$Tabgroup[-1] shall be monitored");

        do {
                foreach my $MyCommands (@Commands) {

                    #foreach my $objCurrentTab  ( @objTab[$Tabgroup[0]-1..$Tabgroup[1]-1] ) {
                        foreach my $objCurrentTab  ( @MonitorTabGroup ) {
                                   $objCurrentTab->Activate;
                                   $objCurrentTab->Screen->Send("$MyCommands\015");
                        }
                        #$objCurrentTab = $objTab[$Tabgroup[0]-1];
                        #$objCurrentTab->Activate;
                                   $crt->sleep($CommandInterval*1000);
                }


                $crt->sleep($TimeIntervalForCommandGroup*1000);
                $MaxTimes -= 1;
        } while $MaxTimes > 0;


}
sub AutoComand {
        my $myscreen =$crt->Screen;
        my $mydialog =$crt->Dialog;
        $myscreen->{'Synchronous'} = $true;
        my $CommandInterval = $mydialog->Prompt("Please assign the timer Interval for command implementation");
        $CommandInterval=1 unless ($CommandInterval);
        $mydialog->MessageBox("the CommandInterval is $CommandInterval second");

        my $TimeIntervalForCommandGroup = $mydialog->Prompt("Please assign the timer Interval for Command Group");
        $TimeIntervalForCommandGroup=90 unless ($TimeIntervalForCommandGroup);
        $mydialog->MessageBox("the Command Group Interval is $TimeIntervalForCommandGroup second");

        my $MaxTimes = $mydialog->Prompt("Please assign MaxTimes for all commands");
        $MaxTimes=100 unless ($MaxTimes);
        $mydialog->MessageBox("the MaxTimes is $MaxTimes");

        my $Commands = $mydialog->Prompt("Please input commands seperated by ',' ");
        if ($Commands) {
            our @Commands = split /,/,$Commands;
        }
        else {
            @Commands=( '{date(),time(),ets:tab2list(plcInfo),plcScheduler:plc_res(3,1000),agsaSippy:count()}.' );
        }
            $mydialog->MessageBox("the Command is @Commands");
        my $device_prompt = $mydialog->Prompt("Please specify the prompt pattern: ");

            $mydialog->MessageBox("the Prompt is $device_prompt");

            #our $realreport = $mydialog->Prompt("Alarm report RealTime ? 1 TO YES, 0 TO NO");
            #$realreport = 1 unless ($RealReport);
            $realreport = 1;

        do {
                $myscreen->WaitForString("$device_prompt");
                foreach my $MyCommand (@Commands) {
                    $myscreen->Send("$MyCommand\015");
                    $crt->sleep($CommandInterval*1000);
                    
                }
                $crt->sleep($TimeIntervalForCommandGroup*1000);
        $MaxTimes -= 1;
        } while $MaxTimes > 0;


}
sub general_interactive_action {
    my $maxtime    = 10000000;
    my $ERROR_COLLECTED_LOGFILE    = 'c:\Users\eyoumxu\Project\Ericsson\SBG\ReportBridge\error_collections.txt';
    my $myscreen =$crt->Screen;
    my $mydialog =$crt->Dialog;
    $myscreen->{'Synchronous'} = $true;
    my @monitored_contents_for = split /;/, $mydialog->Prompt(
                                                        "Please input one or more the content phase seperated by commas you want to monitor"
                                                     );
    my @monitored_contents_from_interactive = @monitored_contents_for;

    my %TriggerCommand;
    my @myonce;

    if (@monitored_contents_for) {
        foreach my $TriggerContent  (@monitored_contents_for) {
                unless ($TriggerContent eq $exception1 || $TriggerContent eq $exception2) {
                    $TriggerCommand{"$TriggerContent"}->{Command} = 
                            $mydialog->Prompt("command triggered by $TriggerContent is ?");

                    if ( $TriggerCommand{$TriggerContent}->{Command} =~ m/(.+)once/ ) {
                        $TriggerCommand{$TriggerContent}->{Command} = $1;
                        $TriggerCommand{$TriggerContent}->{OnOff} = $true;
                        push @myonce,$1;
                    }
                    if ( $TriggerCommand{$TriggerContent}->{Command} =~ m/(.+)routine/ ) {
                        $TriggerCommand{$TriggerContent}->{Command} = $1;
                        $TriggerCommand{$TriggerContent}->{OnOff} = $true;
                        push @routine,$1;
                    }
                    if ($TriggerCommand{$TriggerContent}->{Command} eq "") {
                          $mydialog->MessageBox(
                                                  "Please  specify the command for $TriggerCommand{$TriggerContent}"
                                               );
                          redo;
                    }

                }
        }
    }
    my @routine2 = split /;/, $mydialog->Prompt(
                                                "Please specify the routing commands: "
                                               );
    push @routine,@routine2;

    my $logintime=0;
    
    push @monitored_contents_for,"Freescale"; ### to avoid routing command inputs cause mp/ommp stop at bootloader loadnig phase while ommp/mp restarting
    $TriggerCommand{"Freescale"}="";

    my @alarms=(
"plcCpOverloadAlarm", "Out of memory", "Mnesia is overloaded" ,
"Disable"           , "Disconnect"   , "DISCONNECT"           ,
"Fatal"             , "FATAL"        ,
"OutOfService"      ,
 " failure "        ,
#"_err "             , " error "      , "  ERR "               ,    " abort "      ,
#" Abort "           , " ABORT "      ,
" downgrade "       , " Downgrade "  , " Degrade "            ,    " Degrade "    ,
" SHUTDOWN "        , " Shutdown "   ,
" unavailable "     , " Unavailable ", " UNAVAILABLE "        ,
" Deactive "        , " DEACTIVE "   , " Deactive "           ,
" miss "            , " MISS "       , " Miss "               ,
" crash "           , " CRASH "      , " Crash "              ,
" timeout "         , " Timetout "   , " TIMEOUT "            ,
" abort "           , " Abort "      , " ABORT "              ,
" cannot "          ,
" LOST "            , " lost "       , " Lost "               ,
" unexpected "      , " Unexpected " ,
" abnormal "        , " Abnormal "   ,
"not found"         , "Not Found"    , "NOT FOUD"             ,
"ALALRM"            , "Alarm"        , "alarm",
);



my %megacoCode2= (
qq{ ErrorDescriptor',400 }  => qq{ Megaco Errorcode : Syntax error in message Definition: The transaction request(s) has been disregarded due to a syntax error detected at the message level. The message does not conform to the productions of Messages in Annex A or Annex B as applicable. Used when, for example, no Transaction can be parsed.  can be taken on the receipt of the error message. },
qq{ ErrorDescriptor',401 }  => qq{ Megaco Errorcode : Protocol Error Definition: The transaction request(s) has been disregarded due to a violation of Megaco protocol procedures has been detected. },
qq{ ErrorDescriptor',402 }  => qq{ Megaco Errorcode : Unauthorized Definition: The command is not executed due to the originator of a command is not authorized to execute that command for the termination(s) affected by it.  error text in the error descriptor. },
qq{ ErrorDescriptor',403 }  => qq{ Megaco Errorcode : Syntax Error in TransactionRequest Definition: The transaction request is disregarded since it failed to match production of a TransactionRequest in Annex A, Annex B as applicable. Used when, for example, it is not possible to determine the end of a transaction or when no Action can be parsed.  can be taken on the receipt of the error message.  ITU-T H.248/Annex L (07/2001) 3 },
qq{ ErrorDescriptor',406 }  => qq{ Megaco Errorcode : Version Not Supported Definition: This indicates a lack of support for the protocol version indicated in the message header of the message or in the ServiceChangeVersion parameter. In the case of the version number being indicated in the message header, the message contents are disregarded. },
qq{ ErrorDescriptor',410 }  => qq{ Megaco Errorcode : Incorrect identifier Definition: The transaction request(s) has been disregarded due to a syntax error (illegal length or illegal character) has been found in a mId, transactionId, contextId, terminationId, PropertyId, EventId, SignalId, StatisticsId, ParameterId or requestID.  descriptor.  can be taken on the receipt of the error message. },
qq{ ErrorDescriptor',411 }  => qq{ Megaco Errorcode : The transaction refers to an unknown ContextId Definition: The ContextID referred to by an Action in the Transaction Request is unknown and the Action is therefore disregarded. },
qq{ ErrorDescriptor',412 }  => qq{ Megaco Errorcode : No ContextIDs available Definition: The MG is unable to create a context in response to an Add or Move , command with CHOOSE given as the ContextId, because of a shortage of resources within the MG and the action is disregarded. },
qq{ ErrorDescriptor',411 }  => qq{ Megaco Errorcode : The transaction refers to an unknown ContextId Definition: The ContextID referred to by an Action in the Transaction Request is unknown and the Action is therefore disregarded. },
qq{ ErrorDescriptor',412 }  => qq{ Megaco Errorcode : No ContextIDs available Definition: The MG is unable to create a context in response to an Add or Move , command with CHOOSE given as the ContextId, because of a shortage of resources within the MG and the action is disregarded. },
qq{ ErrorDescriptor',410 }  => qq{ Megaco Errorcode : Incorrect identifier Definition: The transaction request(s) has been disregarded due to a syntax error (illegal length or illegal character) has been found in a mId, transactionId, contextId, terminationId, PropertyId, EventId, SignalId, StatisticsId, ParameterId or requestID.  descriptor.  can be taken on the receipt of the error message. },
qq{ ErrorDescriptor',411 }  => qq{ Megaco Errorcode : The transaction refers to an unknown ContextId Definition: The ContextID referred to by an Action in the Transaction Request is unknown and the Action is therefore disregarded. },
qq{ ErrorDescriptor',412 }  => qq{ Megaco Errorcode : No ContextIDs available Definition: The MG is unable to create a context in response to an Add or Move , command with CHOOSE given as the ContextId, because of a shortage of resources within the MG and the action is disregarded. },
qq{ ErrorDescriptor',421 }  => qq{ Megaco Errorcode : Unknown action or illegal combination of actions Definition: Not used.  4 ITU-T H.248/Annex L (07/2001) },
qq{ ErrorDescriptor',422 }  => qq{ Megaco Errorcode : Syntax Error in Action Definition: The Action was disregarded due to the syntax of an Action did not conform to production of an actionRequest in Annex A or Annex B as applicable. Used when it is not possible to determine the end of an Action, when, for example, no Command can be parsed. },
qq{ ErrorDescriptor',430 }  => qq{ Megaco Errorcode : Unknown TerminationID Definition: The TerminationID referred to by the command is unknown and the command is therefore disregarded.  descriptor. },
qq{ ErrorDescriptor',431 }  => qq{ Megaco Errorcode : No TerminationID matched a wildcard Definition: The command that included one or more wildcard (ALL or CHOOSE) TerminationID(s) is disregarded, since the receiver of the command could not find an existing termination or create a new termination matching the specified pattern. },
qq{ ErrorDescriptor',432 }  => qq{ Megaco Errorcode : Out of TerminationIDs or No TerminationID available Definition: The Add command including the CHOOSE terminationID is disregarded. The MG was unable to provide a TerminationID, because it has exhausted the available range of TerminationIDs. },
qq{ ErrorDescriptor',433 }  => qq{ Megaco Errorcode : TerminationID is already in a Context Definition: A TerminationID specified in an Add command already exists within an active context and therefore the command is disregarded.  ITU-T H.248/Annex L (07/2001) 5 descriptor. },
qq{ ErrorDescriptor',434 }  => qq{ Megaco Errorcode : Max number of Terminations in a Context exceeded Definition: The MGC has requested that a termination be added or moved to a context that already contains a maximum number of terminations allowed. The command is therefore disregarded. },
qq{ ErrorDescriptor',435 }  => qq{ Megaco Errorcode : Termination ID is not in specified Context Definition: A specific TerminationID specified in a Modify, Subtract, AuditValue, AuditCapabilities, or ServiceChange command does not exist in a specified context and therefore the command is disregarded.  the error text in the error descriptor. },
qq{ ErrorDescriptor',440 }  => qq{ Megaco Errorcode : Unsupported or unknown Package Definition: The Package Megaco Errorcode   in a property, parameter, event, signal, or statistic identifier is not supported by the receiver. The command related to the unknown identifier is disregarded.  descriptor. },
qq{ ErrorDescriptor',441 }  => qq{ Megaco Errorcode : Missing Remote or Local Descriptor Definition: The requested command requires that the Remote/Local Descriptor includes necessary or adequate information and therefore the action is not carried out.  command or subsequent commands result in failure to process the requested behaviour (e.g. the bearer set-up fails).  6 ITU-T H.248/Annex L (07/2001) },
qq{ ErrorDescriptor',442 }  => qq{ Megaco Errorcode : Syntax Error in Command Definition: A command request has failed to match the syntax of the commandRequest production and therefore disregarded. Used when, for example, end of a command cannot be determined. },
qq{ ErrorDescriptor',443 }  => qq{ Megaco Errorcode : Unsupported or Unknown Command Definition: The requested Command is not recognized by the receiver and therefore disregarded.  error text in the error descriptor. },
qq{ ErrorDescriptor',444 }  => qq{ Megaco Errorcode : Unsupported or Unknown Descriptor Definition: The descriptor in a Command Request or reply is not recognized by the receiver and therefore disregarded.  the error text in the error descriptor. },
qq{ ErrorDescriptor',445 }  => qq{ Megaco Errorcode : Unsupported or Unknown Property Definition: Property Megaco Errorcode   (Annex A) or ItemID (Annex B) of a property Parameter within a descriptor is recognized but not supported and the command related to the property is not carried out.  included in the error text in the error descriptor. },
qq{ ErrorDescriptor',446 }  => qq{ Megaco Errorcode : Unsupported or Unknown Parameter Definition: The Parameter in a Command Request is not recognized by the receiver and the command related to the descriptor is not carried out.  descriptor.  ITU-T H.248/Annex L (07/2001) 7 },
qq{ ErrorDescriptor',447 }  => qq{ Megaco Errorcode : Descriptor not legal in this command Definition: The descriptor cannot be used in this command in accordance with the definition in Annex A and Annex B and the command including the descriptor is not carried out.  the error text in the error descriptor. },
qq{ ErrorDescriptor',448 }  => qq{ Megaco Errorcode : Descriptor appears twice in a command Definition: The Descriptor appears twice in the command and the command including the descriptor is not carried out.  the error text in the error descriptor. },
qq{ ErrorDescriptor',450 }  => qq{ Megaco Errorcode : No such property in this package Definition: Property Megaco Errorcode   (Annex A) or ItemID (Annex B) of a property Parameter within a Descriptor is not recognized and the command including the property/item is not carried out.  included in the error text in the error descriptor. },
qq{ ErrorDescriptor',451 }  => qq{ Megaco Errorcode : No such event in this package Definition: The command including the Event Megaco Errorcode   is not executed because it is not considered by the MG to be a part of this version of package.  descriptor. },
qq{ ErrorDescriptor',452 }  => qq{ Megaco Errorcode : No such signal in this package Definition: The command including the Signal Megaco Errorcode   is not executed because it is not considered by the MG to be a part of this version of package.  8 ITU-T H.248/Annex L (07/2001) descriptor. },
qq{ ErrorDescriptor',453 }  => qq{ Megaco Errorcode : No such statistic in this package Definition: The command including the Statistic Megaco Errorcode   is not executed because it is not considered by the MG to be a part of this version of package.  descriptor. },
qq{ ErrorDescriptor',454 }  => qq{ Megaco Errorcode : No such parameter value in this package Definition: The command including the parameter value is not executed because it is not considered by the MG to be a part of this version of package.  descriptor. },
qq{ ErrorDescriptor',455 }  => qq{ Megaco Errorcode : Property illegal in this Descriptor Definition: The command including the property was disregarded since the MG does not consider it to be a part of this descriptor.  descriptor. },
qq{ ErrorDescriptor',456 }  => qq{ Megaco Errorcode : Property appears twice in this Descriptor Definition: The command including the property is not executed because the parameter or property appears twice in this descriptor.  descriptor. },
qq{ ErrorDescriptor',457 }  => qq{ Megaco Errorcode : Missing parameter in signal or event Definition: The command was disregarded due to a missing mandatory parameter.  ITU-T H.248/Annex L (07/2001) 9 },
qq{ ErrorDescriptor',471 }  => qq{ Megaco Errorcode : Implied Add for Multiplex failure Definition: A termination listed within a multiplex descriptor could not be added to the current context and the ADD command is not carried out.  descriptor. },
qq{ ErrorDescriptor',500 }  => qq{ Megaco Errorcode : Internal software failure in the MG Definition: A command could not be executed due to a software failure within the MG. },
qq{ ErrorDescriptor',501 }  => qq{ Megaco Errorcode : Not Implemented Definition: A property, parameter, signal, event or statistic mentioned the command has not been implemented. },
qq{ ErrorDescriptor',502 }  => qq{ Megaco Errorcode : Not ready Definition: The command directed to a termination was not executed because of the service state of the termination.  descriptor. },
qq{ ErrorDescriptor',503 }  => qq{ Megaco Errorcode : Service Unavailable Definition: Not used.  10 ITU-T H.248/Annex L (07/2001) },
qq{ ErrorDescriptor',504 }  => qq{ Megaco Errorcode : Command Received from unauthorized entity Definition: Not used. },
qq{ ErrorDescriptor',505 }  => qq{ Megaco Errorcode : Transaction Request Received before a ServiceChange Reply has been received Definition: Sent by the MG/MGC which has sent a ServiceChange request to an MGC/MG and receives a transaction request from that MGC/MG before it has received the corresponding ServiceChange reply. The actions included in the transaction request are not carried out. },
qq{ ErrorDescriptor',510 }  => qq{ Megaco Errorcode : Insufficient resources Definition: The command(s) was rejected due to lack of common resources in the MG. }
);


my %megacoCode= (
qq{ Error = 400 }  => qq{ Megaco Errorcode : Syntax error in message Definition: The transaction request(s) has been disregarded due to a syntax error detected at the message level. The message does not conform to the productions of Messages in Annex A or Annex B as applicable. Used when, for example, no Transaction can be parsed.  can be taken on the receipt of the error message. },
qq{ Error = 401 }  => qq{ Megaco Errorcode : Protocol Error Definition: The transaction request(s) has been disregarded due to a violation of Megaco protocol procedures has been detected. },
qq{ Error = 402 }  => qq{ Megaco Errorcode : Unauthorized Definition: The command is not executed due to the originator of a command is not authorized to execute that command for the termination(s) affected by it.  error text in the error descriptor. },
qq{ Error = 403 }  => qq{ Megaco Errorcode : Syntax Error in TransactionRequest Definition: The transaction request is disregarded since it failed to match production of a TransactionRequest in Annex A, Annex B as applicable. Used when, for example, it is not possible to determine the end of a transaction or when no Action can be parsed.  can be taken on the receipt of the error message.  ITU-T H.248/Annex L (07/2001) 3 },
qq{ Error = 406 }  => qq{ Megaco Errorcode : Version Not Supported Definition: This indicates a lack of support for the protocol version indicated in the message header of the message or in the ServiceChangeVersion parameter. In the case of the version number being indicated in the message header, the message contents are disregarded. },
qq{ Error = 410 }  => qq{ Megaco Errorcode : Incorrect identifier Definition: The transaction request(s) has been disregarded due to a syntax error (illegal length or illegal character) has been found in a mId, transactionId, contextId, terminationId, PropertyId, EventId, SignalId, StatisticsId, ParameterId or requestID.  descriptor.  can be taken on the receipt of the error message. },
qq{ Error = 411 }  => qq{ Megaco Errorcode : The transaction refers to an unknown ContextId Definition: The ContextID referred to by an Action in the Transaction Request is unknown and the Action is therefore disregarded. },
qq{ Error = 412 }  => qq{ Megaco Errorcode : No ContextIDs available Definition: The MG is unable to create a context in response to an Add or Move , command with CHOOSE given as the ContextId, because of a shortage of resources within the MG and the action is disregarded. },
qq{ Error = 411 }  => qq{ Megaco Errorcode : The transaction refers to an unknown ContextId Definition: The ContextID referred to by an Action in the Transaction Request is unknown and the Action is therefore disregarded. },
qq{ Error = 412 }  => qq{ Megaco Errorcode : No ContextIDs available Definition: The MG is unable to create a context in response to an Add or Move , command with CHOOSE given as the ContextId, because of a shortage of resources within the MG and the action is disregarded. },
qq{ Error = 410 }  => qq{ Megaco Errorcode : Incorrect identifier Definition: The transaction request(s) has been disregarded due to a syntax error (illegal length or illegal character) has been found in a mId, transactionId, contextId, terminationId, PropertyId, EventId, SignalId, StatisticsId, ParameterId or requestID.  descriptor.  can be taken on the receipt of the error message. },
qq{ Error = 411 }  => qq{ Megaco Errorcode : The transaction refers to an unknown ContextId Definition: The ContextID referred to by an Action in the Transaction Request is unknown and the Action is therefore disregarded. },
qq{ Error = 412 }  => qq{ Megaco Errorcode : No ContextIDs available Definition: The MG is unable to create a context in response to an Add or Move , command with CHOOSE given as the ContextId, because of a shortage of resources within the MG and the action is disregarded. },
qq{ Error = 421 }  => qq{ Megaco Errorcode : Unknown action or illegal combination of actions Definition: Not used.  4 ITU-T H.248/Annex L (07/2001) },
qq{ Error = 422 }  => qq{ Megaco Errorcode : Syntax Error in Action Definition: The Action was disregarded due to the syntax of an Action did not conform to production of an actionRequest in Annex A or Annex B as applicable. Used when it is not possible to determine the end of an Action, when, for example, no Command can be parsed. },
qq{ Error = 430 }  => qq{ Megaco Errorcode : Unknown TerminationID Definition: The TerminationID referred to by the command is unknown and the command is therefore disregarded.  descriptor. },
qq{ Error = 431 }  => qq{ Megaco Errorcode : No TerminationID matched a wildcard Definition: The command that included one or more wildcard (ALL or CHOOSE) TerminationID(s) is disregarded, since the receiver of the command could not find an existing termination or create a new termination matching the specified pattern. },
qq{ Error = 432 }  => qq{ Megaco Errorcode : Out of TerminationIDs or No TerminationID available Definition: The Add command including the CHOOSE terminationID is disregarded. The MG was unable to provide a TerminationID, because it has exhausted the available range of TerminationIDs. },
qq{ Error = 433 }  => qq{ Megaco Errorcode : TerminationID is already in a Context Definition: A TerminationID specified in an Add command already exists within an active context and therefore the command is disregarded.  ITU-T H.248/Annex L (07/2001) 5 descriptor. },
qq{ Error = 434 }  => qq{ Megaco Errorcode : Max number of Terminations in a Context exceeded Definition: The MGC has requested that a termination be added or moved to a context that already contains a maximum number of terminations allowed. The command is therefore disregarded. },
qq{ Error = 435 }  => qq{ Megaco Errorcode : Termination ID is not in specified Context Definition: A specific TerminationID specified in a Modify, Subtract, AuditValue, AuditCapabilities, or ServiceChange command does not exist in a specified context and therefore the command is disregarded.  the error text in the error descriptor. },
qq{ Error = 440 }  => qq{ Megaco Errorcode : Unsupported or unknown Package Definition: The Package Megaco Errorcode   in a property, parameter, event, signal, or statistic identifier is not supported by the receiver. The command related to the unknown identifier is disregarded.  descriptor. },
qq{ Error = 441 }  => qq{ Megaco Errorcode : Missing Remote or Local Descriptor Definition: The requested command requires that the Remote/Local Descriptor includes necessary or adequate information and therefore the action is not carried out.  command or subsequent commands result in failure to process the requested behaviour (e.g. the bearer set-up fails).  6 ITU-T H.248/Annex L (07/2001) },
qq{ Error = 442 }  => qq{ Megaco Errorcode : Syntax Error in Command Definition: A command request has failed to match the syntax of the commandRequest production and therefore disregarded. Used when, for example, end of a command cannot be determined. },
qq{ Error = 443 }  => qq{ Megaco Errorcode : Unsupported or Unknown Command Definition: The requested Command is not recognized by the receiver and therefore disregarded.  error text in the error descriptor. },
qq{ Error = 444 }  => qq{ Megaco Errorcode : Unsupported or Unknown Descriptor Definition: The descriptor in a Command Request or reply is not recognized by the receiver and therefore disregarded.  the error text in the error descriptor. },
qq{ Error = 445 }  => qq{ Megaco Errorcode : Unsupported or Unknown Property Definition: Property Megaco Errorcode   (Annex A) or ItemID (Annex B) of a property Parameter within a descriptor is recognized but not supported and the command related to the property is not carried out.  included in the error text in the error descriptor. },
qq{ Error = 446 }  => qq{ Megaco Errorcode : Unsupported or Unknown Parameter Definition: The Parameter in a Command Request is not recognized by the receiver and the command related to the descriptor is not carried out.  descriptor.  ITU-T H.248/Annex L (07/2001) 7 },
qq{ Error = 447 }  => qq{ Megaco Errorcode : Descriptor not legal in this command Definition: The descriptor cannot be used in this command in accordance with the definition in Annex A and Annex B and the command including the descriptor is not carried out.  the error text in the error descriptor. },
qq{ Error = 448 }  => qq{ Megaco Errorcode : Descriptor appears twice in a command Definition: The Descriptor appears twice in the command and the command including the descriptor is not carried out.  the error text in the error descriptor. },
qq{ Error = 450 }  => qq{ Megaco Errorcode : No such property in this package Definition: Property Megaco Errorcode   (Annex A) or ItemID (Annex B) of a property Parameter within a Descriptor is not recognized and the command including the property/item is not carried out.  included in the error text in the error descriptor. },
qq{ Error = 451 }  => qq{ Megaco Errorcode : No such event in this package Definition: The command including the Event Megaco Errorcode   is not executed because it is not considered by the MG to be a part of this version of package.  descriptor. },
qq{ Error = 452 }  => qq{ Megaco Errorcode : No such signal in this package Definition: The command including the Signal Megaco Errorcode   is not executed because it is not considered by the MG to be a part of this version of package.  8 ITU-T H.248/Annex L (07/2001) descriptor. },
qq{ Error = 453 }  => qq{ Megaco Errorcode : No such statistic in this package Definition: The command including the Statistic Megaco Errorcode   is not executed because it is not considered by the MG to be a part of this version of package.  descriptor. },
qq{ Error = 454 }  => qq{ Megaco Errorcode : No such parameter value in this package Definition: The command including the parameter value is not executed because it is not considered by the MG to be a part of this version of package.  descriptor. },
qq{ Error = 455 }  => qq{ Megaco Errorcode : Property illegal in this Descriptor Definition: The command including the property was disregarded since the MG does not consider it to be a part of this descriptor.  descriptor. },
qq{ Error = 456 }  => qq{ Megaco Errorcode : Property appears twice in this Descriptor Definition: The command including the property is not executed because the parameter or property appears twice in this descriptor.  descriptor. },
qq{ Error = 457 }  => qq{ Megaco Errorcode : Missing parameter in signal or event Definition: The command was disregarded due to a missing mandatory parameter.  ITU-T H.248/Annex L (07/2001) 9 },
qq{ Error = 471 }  => qq{ Megaco Errorcode : Implied Add for Multiplex failure Definition: A termination listed within a multiplex descriptor could not be added to the current context and the ADD command is not carried out.  descriptor. },
qq{ Error = 500 }  => qq{ Megaco Errorcode : Internal software failure in the MG Definition: A command could not be executed due to a software failure within the MG. },
qq{ Error = 501 }  => qq{ Megaco Errorcode : Not Implemented Definition: A property, parameter, signal, event or statistic mentioned the command has not been implemented. },
qq{ Error = 502 }  => qq{ Megaco Errorcode : Not ready Definition: The command directed to a termination was not executed because of the service state of the termination.  descriptor. },
qq{ Error = 503 }  => qq{ Megaco Errorcode : Service Unavailable Definition: Not used.  10 ITU-T H.248/Annex L (07/2001) },
qq{ Error = 504 }  => qq{ Megaco Errorcode : Command Received from unauthorized entity Definition: Not used. },
qq{ Error = 505 }  => qq{ Megaco Errorcode : Transaction Request Received before a ServiceChange Reply has been received Definition: Sent by the MG/MGC which has sent a ServiceChange request to an MGC/MG and receives a transaction request from that MGC/MG before it has received the corresponding ServiceChange reply. The actions included in the transaction request are not carried out. },
qq{ Error = 510 }  => qq{ Megaco Errorcode : Insufficient resources Definition: The command(s) was rejected due to lack of common resources in the MG. }
);
my %sipCode = (
qq{ SIP/2.0 199 }  => qq{ Early Dialog Terminated Can be used by User Agent Server to indicate to upstream SIP entities (including the User Agent Client (UAC)) that an early dialog has been terminated. },
qq{ SIP/2.0 204 }  => qq{ No Notification Indicates the request was successful, but the corresponding response will not be received. },
qq{ SIP/2.0 300 }  => qq{ Multiple Choices The address resolved to one of several options for the user or client to choose between, which are listed in the message body or the message's Contact fields. },
qq{ SIP/2.0 301 }  => qq{ Moved Permanently The original Request-URI is no longer valid, the new address is given in the Contact header field, and the client should update any records of the original Request-URI with the new value. },
qq{ SIP/2.0 302 }  => qq{ Moved Temporarily The client should try at the address in the Contact field. If an Expires field is present, the client may cache the result for that period of time. },
qq{ SIP/2.0 305 }  => qq{ Use Proxy The Contact field details a proxy that must be used to access the requested destination. },
qq{ SIP/2.0 380 }  => qq{ Alternative Service The call failed, but alternatives are detailed in the message body. },
qq{ SIP/2.0 400 }  => qq{ Bad Request The request could not be understood due to malformed syntax. },
qq{ SIP/2.0 401 }  => qq{ Unauthorized The request requires user authentication. This response is issued by UASs and registrars. },
qq{ SIP/2.0 402 }  => qq{ Payment Required Reserved for future use. },
qq{ SIP/2.0 403 }  => qq{ Forbidden The server understood the request, but is refusing to fulfil it. },
qq{ SIP/2.0 404 }  => qq{ Not Found The server has definitive information that the user does not exist at the domain specified in the Request-URI. This status is also returned if the domain in the Request-URI does not match any of the domains handled by the recipient of the request. },
qq{ SIP/2.0 405 }  => qq{ Method Not Allowed The method specified in the Request-Line is understood, but not allowed for the address identified by the Request-URI. },
qq{ SIP/2.0 406 }  => qq{ Not Acceptable The resource identified by the request is only capable of generating response entities that have content characteristics but not acceptable according to the Accept header field sent in the request. },
qq{ SIP/2.0 407 }  => qq{ Proxy Authentication Required The request requires user authentication. This response is issued by proxys. },
qq{ SIP/2.0 408 }  => qq{ Request Timeout Couldn't find the user in time. The server could not produce a response within a suitable amount of time, for example, if it could not determine the location of the user in time. The client MAY repeat the request without modifications at any later time.  },
qq{ SIP/2.0 409 }  => qq{ Conflict User already registered. },
qq{ SIP/2.0 410 }  => qq{ Gone The user existed once, but is not available here any more. },
qq{ SIP/2.0 411 }  => qq{ Length Required The server will not accept the request without a valid Content-Length. },
qq{ SIP/2.0 412 }  => qq{ Conditional Request Failed The given precondition has not been met. },
qq{ SIP/2.0 413 }  => qq{ Request Entity Too Large Request body too large. },
qq{ SIP/2.0 414 }  => qq{ Request-URI Too Long The server is refusing to service the request because the Request-URI is longer than the server is willing to interpret. },
qq{ SIP/2.0 415 }  => qq{ Unsupported Media Type Request body in a format not supported. },
qq{ SIP/2.0 416 }  => qq{ Unsupported URI Scheme Request-URI is unknown to the server. },
qq{ SIP/2.0 417 }  => qq{ Unknown Resource-Priority There was a resource-priority option tag, but no Resource-Priority header. },
qq{ SIP/2.0 420 }  => qq{ Bad Extension Bad SIP Protocol Extension used, not understood by the server. },
qq{ SIP/2.0 421 }  => qq{ Extension Required The server needs a specific extension not listed in the Supported header. },
qq{ SIP/2.0 422 }  => qq{ Session Interval Too Small The received request contains a Session-Expires header field with a duration below the minimum timer. },
qq{ SIP/2.0 423 }  => qq{ Interval Too Brief Expiration time of the resource is too short. },
qq{ SIP/2.0 424 }  => qq{ Bad Location Information The request's location content was malformed or otherwise unsatisfactory. },
qq{ SIP/2.0 428 }  => qq{ Use Identity Header The server policy requires an Identity header, and one has not been provided. },
qq{ SIP/2.0 429 }  => qq{ Provide Referrer Identity The server did not receive a valid Referred-By token on the request. },
qq{ SIP/2.0 430 }  => qq{ Flow Failed A specific flow to a user agent has failed, although other flows may succeed. This response is intended for use between proxy devices, and should not be seen by an endpoint (and if it is seen by one, should be treated as a 400 Bad Request response). },
qq{ SIP/2.0 433 }  => qq{ Anonymity Disallowed The request has been rejected because it was anonymous. },
qq{ SIP/2.0 436 }  => qq{ Bad Identity-Info The request has an Identity-Info header, and the URI scheme in that header cannot be dereferenced. },
qq{ SIP/2.0 437 }  => qq{ Unsupported Certificate The server was unable to validate a certificate for the domain that signed the request. },
qq{ SIP/2.0 438 }  => qq{ Invalid Identity Header The server obtained a valid certificate that the request claimed was used to sign the request, but was unable to verify that signature. },
qq{ SIP/2.0 439 }  => qq{ First Hop Lacks Outbound Support The first outbound proxy the user is attempting to register through does not support the outbound feature of RFC 5626, although the registrar does. }, 
qq{ SIP/2.0 470 }  => qq{ Consent Needed The source of the request did not have the permission of the recipient to make such a request. },
qq{ SIP/2.0 480 }  => qq{ Temporarily Unavailable Callee currently unavailable. },
qq{ SIP/2.0 481 }  => qq{ Call/Transaction Does Not Exist Server received a request that does not match any dialog or transaction. },
qq{ SIP/2.0 482 }  => qq{ Loop Detected.  Server has detected a loop. },
qq{ SIP/2.0 483 }  => qq{ Too Many Hops Max-Forwards header has reached the value '0'. },
qq{ SIP/2.0 484 }  => qq{ Address Incomplete Request-URI incomplete. },
qq{ SIP/2.0 485 }  => qq{ Ambiguous Request-URI is ambiguous. },
qq{ SIP/2.0 486 }  => qq{ Busy Here Callee is busy. },
qq{ SIP/2.0 487 }  => qq{ Request Terminated Request has terminated by bye or cancel. },
qq{ SIP/2.0 488 }  => qq{ Not Acceptable Here Some aspect of the session description or the Request-URI is not acceptable. },
qq{ SIP/2.0 489 }  => qq{ Bad Event The server did not understand an event package specified in an Event header field. },
qq{ SIP/2.0 491 }  => qq{ Request Pending Server has some pending request from the same dialog. },
qq{ SIP/2.0 503 }  => qq{ Service Unavailable The server is undergoing maintenance or is temporarily overloaded and so cannot process the request. A Retry-After header field may specify when the client may reattempt its request. }, 
qq{ SIP/2.0 504 }  => qq{ Server Time-out The server attempted to access another server in attempting to process the request, and did not receive a prompt response. },
qq{ SIP/2.0 505 }  => qq{ Version Not Supported The SIP protocol version in the request is not supported by the server. },
qq{ SIP/2.0 513 }  => qq{ Message Too Large The request message length is longer than the server can process. },
qq{ SIP/2.0 580 }  => qq{ Precondition Failure The server is unable or unwilling to meet some constraints specified in the offer. },
qq{ SIP/2.0 600 }  => qq{ Busy Everywhere All possible destinations are busy. Unlike the 486 response, this response indicates the destination knows there are no alternative destinations (such as a voicemail server) able to accept the call. },
qq{ SIP/2.0 603 }  => qq{ Decline The destination does not wish to participate in the call, or cannot do so, and additionally the destination knows there are no alternative destinations (such as a voicemail server) willing to accept the call. },
qq{ SIP/2.0 604 }  => qq{ Does Not Exist Anywhere The server has authoritative information that the requested user does not exist anywhere. },
qq{ SIP/2.0 606 }  => qq{ Not Acceptable }
);

    $erl_shell_report_error_label ="=ERROR REPORT=";

    push @monitored_contents_for,@alarms;
    push @monitored_contents_for,$erl_shell_report_error_label;
    push @monitored_contents_for,keys(%sipCode);
    push @monitored_contents_for,keys(%megacoCode);
    push @monitored_contents_for,keys(%megacoCode2);




    my $exception1=qq~exception error~;
    my $exception2=qq~syntax error~;
    push @monitored_contents_for,$exception1;
    push @monitored_contents_for,$exception2;

    $erl_shell_report_second_seperator = "=============";
    $erl_shell_report_seperator = "=INFO REPORT=";
    $router_interactive_prompt="-- More --";
    $blade_restart_pattern="-------------------------Start--------------------------";
    $blade_restart_pattern2=qq{U-Boot};
    $mp_wait_for_reset_pattern=qq{=>};


    unshift @monitored_contents_for,$blade_restart_pattern;
    unshift @monitored_contents_for,$blade_restart_pattern2;
    unshift @monitored_contents_for,$router_interactive_prompt;
#    unshift @monitored_contents_for,$mp_wait_for_reset_pattern;




    my $errorCode=0;
    my %alarmtimer_of;
    my %alarm_occur_times_of;
    my %alarm_ignore_times=0;
    my $is_in_restarting = 0;
    my $is_msgbox_noisy = 1;
    my $Index = 0;
    my @monitored_contents_back = @monitored_contents_for;
#    my @MonitorNull = ("ajsjajdgjfjgdfgjsjfgfad");

    while ( $maxtime >0 ) {
        my $device_prompt="";
        while ( $device_prompt eq "" or !defined($device_prompt) or $device_prompt =~ /^\s+/xm) {
            do {
                 my $myCursorMoved = $crt->Screen->WaitForCursor(1);
             } until $myCursorMoved == 0;
             my $row = $myscreen->CurrentRow;
             my $col = $myscreen->CurrentColumn -1;
             $device_prompt = $myscreen->Get($row,0,$row,$col);
        }

         $device_prompt =~ s/(\(ppb.+blade.+\)).*/$1/;
         my $eror_context_captured_info = 0;

         foreach my $alarm (keys(%alarmtimer_of)) {
             if ($alarmtimer_of{$alarm} > 0 ) {
                 $alarmtimer_of{$alarm}--;
             }
             else {
                 push @monitored_contents_for,$alarm;
                 delete $alarmtimer_of{$alarm};
             }
         }

        if ($is_in_restarting == 0) {
            $Index = $myscreen->WaitForStrings(@monitored_contents_for,30); 
        }
        else{
            #$mydialog->MessageBox("\$is_in_restarting is $is_in_restarting") if $is_msgbox_noisy == 1;
            $alarm_ignore_times++;
            #$mydialog->MessageBox("\$alarm_ignore_times is $alarm_ignore_times") if $is_msgbox_noisy == 1;
            if($alarm_ignore_times == 4) {
                $is_in_restarting = 0;
                $is_msgbox_noisy = 1;
                $alarm_ignore_times=0;
                @monitored_contents_for = @monitored_contents_back;
            }
            $Index = $myscreen->WaitForStrings(@monitored_contents_for,30); 
        }


        unless ( $Index == 0 ) {

                                if ( $monitored_contents_for[$Index-1] eq qq{$mp_wait_for_reset_pattern}) {
                                        $crt->sleep(1000);
                                        $myscreen->Send("reset\015");
                                }

                                
                                if ( $monitored_contents_for[$Index-1] eq "$router_interactive_prompt" 
                                                    or 
                                                    grep /$monitored_contents_for[$Index-1]/, @monitored_contents_from_interactive) {

                                     $alarm_occur_times_of{$monitored_contents_for[$Index-1]} = 0; 
                                }
                                else {
                                    $alarm_occur_times_of{$monitored_contents_for[$Index-1]}++ 
                                }

                                if ($alarm_occur_times_of{$monitored_contents_for[$Index-1]} > 10) {
                                    $alarmtimer_of{$monitored_contents_for[$Index-1]} = 10;
                                    $alarm_occur_times_of{$monitored_contents_for[$Index-1]} = 0;
                                    splice @monitored_contents_for, $Index-1,1;
                                }
                                if ( grep /$TriggerCommand{$monitored_contents_for[$Index-1]}->{Command}/, @myonce ) {
                                    $myscreen->Send("$TriggerCommand{$monitored_contents_for[$Index-1]}->{Command}\015")
                                            if ( $TriggerCommand{$monitored_contents_for[$Index-1]}->{OnOff} == $true );
                                    $TriggerCommand{$monitored_contents_for[$Index-1]}->{OnOff} = $false;
                                }
                                elsif ( grep /$monitored_contents_for[$Index-1]/, @alarms ) {
                                      $crt->GetScriptTab->Activate;
                                      if ($monitored_contents_for[$Index-1] eq "plcCpOverloadAlarm") {
                                          $myscreen->Send(                      "{date(),
                                                                                  time(),
                                                                   ets:tab2list(plcInfo),
                                                            plcScheduler:plc_res(3,1000),
                                                                 agsaSippy:count()}.\15"
                                                         );
                                      }elsif ( $monitored_contents_for[$Index-1] ne "Err:" ) {
                                            $eror_context_captured_info = $myscreen->ReadString("$device_prompt",2);
                                            $mydialog->MessageBox(qq{notification: Maybe a ERROR happened: $monitored_contents_for[$Index-1]}) if $is_msgbox_noisy == 1;
                                            $eror_context_captured_info = 0;
                                      }
                                }
                                elsif ( $Index == @monitored_contents_for || $Index == $#monitored_contents_for )  {
                                        $TriggerCommand{$monitored_contents_for[$Index-1]}->{OnOff} = $true;
                                }
                                elsif ( $monitored_contents_for[$Index-1] eq $erl_shell_report_error_label ) {
                                            $mydialog->MessageBox(qq{Error Report}) if $is_msgbox_noisy == 1;
                                        $crt->GetScriptTab->Activate;
                                        $eror_context_captured_info = 
                                                $myscreen->ReadString(                  "$device_prompt",
                                                                           "$erl_shell_report_seperator",
                                                                    "$erl_shell_report_second_seperator",
                                                                                                       2
                                                                     );
                                }
                                elsif ( grep /$monitored_contents_for[$Index-1]/, keys(%megacoCode)) {
                                        $crt->GetScriptTab->Activate;

                                        $eror_context_captured_info = 
                                                $myscreen->ReadString(                  "$device_prompt",
                                                                           "$erl_shell_report_seperator",
                                                                    "$erl_shell_report_second_seperator",
                                                                                                       2
                                                                     );

                                        $mydialog->MessageBox("$megacoCode{$monitored_contents_for[$Index-1]}") if $is_msgbox_noisy == 1;
                                }
                                elsif ( grep /$monitored_contents_for[$Index-1]/, keys(%megacoCode2)) {
                                        $crt->GetScriptTab->Activate;

                                        $eror_context_captured_info = 
                                                $myscreen->ReadString(                  "$device_prompt",
                                                                           "$erl_shell_report_seperator",
                                                                    "$erl_shell_report_second_seperator",
                                                                                                       2
                                                                     );

                                        $mydialog->MessageBox("$megacoCode2{$monitored_contents_for[$Index-1]}") if $is_msgbox_noisy == 1;
                                }
                                elsif ( grep /$monitored_contents_for[$Index-1]/, keys(%sipCode) ) {
                                        $crt->GetScriptTab->Activate;
                                        $eror_context_captured_info = $myscreen->ReadString(                "$device_prompt",
                                                                                               "$erl_shell_report_seperator",
                                                                                        "$erl_shell_report_second_seperator",
                                                                                                                           2
                                                                                           );


                                        $mydialog->MessageBox("$sipCode{$monitored_contents_for[$Index-1]}") if $is_msgbox_noisy == 1;
                                }
                                elsif ( $monitored_contents_for[$Index-1] eq "$blade_restart_pattern"
                                        or
                                        $monitored_contents_for[$Index-1] eq "$blade_restart_pattern2"
                                      ) {

                                        $is_in_restarting = 1;
                                        $is_msgbox_noisy = 0;
                                        @monitored_contents_for = ("$mp_wait_for_reset_pattern");
                                        $mydialog->MessageBox("restarting now..., start to monitor @monitored_contents_for");
                                }
                               #elsif ( $monitored_contents_for[$Index-1] eq qq{$mp_wait_for_reset_pattern}) {
                               #        $mydialog->MessageBox("here");
                               #        $myscreen->Send("reset\015");
                               #}
                                elsif ( $monitored_contents_for[$Index-1] eq "$router_interactive_prompt") {
                                        $myscreen->Send("\015");
                                        while($myscreen->ReadString("$router_interactive_prompt",1)) {
                                            $myscreen->Send("\015");
                                        }
                                }
                                else {
                                         $myscreen->Send("$TriggerCommand{$monitored_contents_for[$Index-1]}->{Command}\015") 
                                                 if $monitored_contents_for[$Index-1] ne "Freescale";
                                         $logintime++;

                                }
                                if ($eror_context_captured_info) {
                                     open my $ERROR_COLLECTED_LOGFILE,
                                                 '>>',
                                                 $ERROR_COLLECTED_LOGFILE
                                     or die "can not open this file";
                                     print $ERROR_COLLECTED_LOGFILE $device_prompt;
                                     print $ERROR_COLLECTED_LOGFILE "\n";
                                     print $ERROR_COLLECTED_LOGFILE  $eror_context_captured_info;
                                     print $ERROR_COLLECTED_LOGFILE "\n";
                                     close $ERROR_COLLECTED_LOGFILE;
                                     $mydialog->MessageBox("Note: $eror_context_captured_info") if $is_msgbox_noisy == 1;
                                }
                    
        }
        else  {
                if ($device_prompt =~ /blade.+homer\$/) {
                    $myscreen->Send("to\015");
                }
                elsif($device_prompt =~ /ppb\d_bs\d/){
                     foreach my $command (@routine) {
                        $myscreen->Send("$command\015");
                        my $try_matched_times = 0;
                        while($myscreen->ReadString("$router_interactive_prompt",1,$true)) {
                            $myscreen->Send("\015");
                            $try_matched_times++;
                            last if $try_matched_times == 5;
                        }
                     }
                     $try_matched_times = 0;
                     while($myscreen->MatchIndex != 1) {
                            $myscreen->ReadString("$device_prompt",1);
                            $try_matched_times++;
                            last if $try_matched_times == 3;
                     }
                }
        }

        $maxtime--;
    }
      $mydialog->MessageBox("quit here") if $is_msgbox_noisy == 1;

}
