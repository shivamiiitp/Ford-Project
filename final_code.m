clc;
clear All;
fclose all;
input_zip_folder="C:\Users\shivam.upadhyay\Desktop\Project\Final Code\Ford_CHN_B515_LB69741_81300333_20200131_021846_MEA_0326.ZIP";
%output_folder="C:\Users\shivam.upadhyay\Desktop\Project\Final Code\Output Files";
output_folder="C:\Users\shivam.upadhyay\Desktop\Project\Final Code\Testing";
lookup_table="C:\Users\shivam.upadhyay\Desktop\Project\Final Code\DTC Final.xlsx";
output_table="C:\Users\shivam.upadhyay\Desktop\Project\Final Code\Output_table.csv";
from_date="22-02-2010";
to_date="02-12-2020";
Main_Function(input_zip_folder,output_folder,lookup_table,output_table,from_date,to_date);



%Main Function which perform main tasks
function Main_Function(input_zip_file,output_file,lookup_table,output_table,from_date,to_date)
        %unzipping(input_zip_file,output_file);                  %unzipping zipped folder
        output_info=[;];                                        %output table to be written in output.csv
        table_data=readtable(lookup_table);                     %table data of lookup table
        dat_file=list_dat_file(output_file);
        disp(dat_file);
        vin=getVinId(dat_file{1});
        table_dtc_codes=table_data(:,1);                        %first row of table
        height_dtc_codes=height(table_dtc_codes);               %no of rows in table
        t_files=list_t_files(output_file);                      %getting all files with .0t* extension
        disp(t_files);                                          %displaying .t0* files
        for i=1:length(t_files)                                 %'for' loop for processing every .t0* files
            StandardReadDiagnosticTroublecode_pres=isStandardReadDiagnosticTroublecode(t_files{i});
            if strcmp(StandardReadDiagnosticTroublecode_pres,'true')
                l=message_header_length(t_files{i});                %Message Header Length
                dtc_codes=read_t_files(t_files{i},l);               %Fetching all dtc codes present in it
                date_str=getDate(t_files{i});
                date=datetime(date_str,'Format','dd.MM.yyyy');
                disp("Date:");
                disp(date);                                   
                disp("Message Header Length:");    
                disp(l);
                disp("DTC Code in this File:");
            for j=1:length(dtc_codes)                              %'for' loop for processing each dtc codes present in each .t0*
                flag='false';                                      %flag for checking if code in .t0* is present in lookup table or not
                disp(dtc_codes{j});
                input="0x"+string(dtc_codes{j});                   %adding "0x" in dtc code from .t0* file to compare with lookup table
                for k=1:height_dtc_codes                           %for searching fetched dtc code in look up table
                    if strcmp(input,table_dtc_codes(k,1).(1))      
                        flag='true';                                %if dtc code is present flag='true'
                        information=table_data(k,3).(1);            %Information associated with dtc code in lookup table
                        disp(information);
                        output_info=[output_info;table({input},{information},{date})];%appending each table from each .t0* files to final table
                    end
                end
                if strcmp(flag,'false')                                %to check if dtc code is found in lookup table or not
                    disp("Sorry Code Not Found");
                    output_info=[output_info;table({input},{"Unknown Code"},{date})];
                end
            end
            disp(" ");
            disp("%%%Details Ends Here");   
            disp("  ");
    
            end
        end
        
        
        from_date=datetime(from_date,'InputFormat',"dd-MM-yyyy");
        to_date=datetime(to_date,'InputFormat',"dd-MM-yyyy");
        further_process(output_info,from_date,to_date,output_table,vin);
        %output_info.Properties.VariableNames={'DTC_Hex_Code','Information','Date'};    %Defining rowname and column name in output table file
         %writetable(output_info,output_table);                                  %writing final output table to csv file
        
end

%Function further process
function further_process(t1,from_date,to_date,output_table,vin)
        t2=[;];
        for i=1:height(t1)
            t_row=t1(i,3).(1);
            disp(class(t_row{1}));
            disp(t_row{1});
            dtc_code=t1(i,1).(1);
            info=t1(i,2).(1);
            if from_date<=t_row{1} && t_row{1}<=to_date
                 t2=[t2;table({dtc_code},{info},{t_row{1}})];
            end
           
        end
        disp(t2);
        final_table=dtc_count_details(t2,vin);
        final_table.Properties.VariableNames={'DTC_Hex_Code','Information','DTC_Count','Recent_DTC_Count','Recent_Date','Past_DTC_Count','Past_Date','Vehicle_ID'};
        final_table=unique(final_table(:,:),'rows');
        disp(final_table);
        writetable(final_table,output_table); 
end

%Function for counting dtc
function t=dtc_count_details(t2,vin)
    disp(t2);
    final_table=[;];
    for i=1:height(t2)
        count=0;
        dates_=datetime.empty;
        element=t2(i,1).(1){1}{1};
        disp(element);
        disp(class(element));
        for j=1:height(t2)
            if t2(j,1).(1){1}{1}==element
                disp(t2(j,3).(1){1});
                dates_=[dates_, t2(j,3).(1){1}];
                count=count+1;
            end
        end
        disp(dates_);
        disp(class(dates_));
        disp(max(dates_));
        recent_date=max(dates_);
        past_date=second_largest_date(dates_);
        recentCount=recent_dtc_count(dates_);
        
        past_dtc_count=count-recentCount;
        
        final_table=[final_table;table({t2(i,1).(1){1}{1}{1}},{t2(i,2).(1){1}{1}{1}},count,recentCount,recent_date,past_dtc_count,past_date,{vin})];
    end
    t=final_table;
end


%Function for Past Date 
function r=second_largest_date(arr)
        if length(unique(arr))~=1
            r=max(arr(arr<(max(arr))));
        else
            r=arr(1);
        end
        
end

%%Function for recent DTC Count
function count=recent_dtc_count(dates)
        smallest_date=min(dates);
        largest_date=max(dates);
        count=0;
        date_difference=datenum(largest_date)-datenum(smallest_date);
        if date_difference>=3
            for i=1:length(dates)
                if dates(i)>= (largest_date-3)
                    count=count+1;
                end
            end
            
        elseif date_difference==2
             count=length(dates);
        elseif date_difference==1
             count=length(dates);
        else
            count=length(dates);
        end
end

%Function to Check if CDS is present or Not  
function bool_val=isStandardReadDiagnosticTroublecode(filename)
        bool_val='false';
        fid=fopen(filename,'r');
        while ~feof(fid)
            text=fgetl(fid);
            if contains(text,"StandardReadDiagnosticTroublecode")
                bool_val='true';
                break;
            end
        end
        fclose(fid);
end



%Function for getting Vehicle Id
function vin=getVinId(filename)
    fid=fopen(filename,'r');
    while ~feof(fid)
        text=fgetl(fid);
        if contains(text,"VIN")
            text2=fgetl(fid);
            vin=text2(5:length(text2));
            break;
        end
    end
    fclose(fid);
end
%Function to return DTC codes from .t0* files
function dtc_codes=read_t_files(t_file,message_header_len)
    fid=fopen(t_file,'r');
    dtc_codes=[];
    while ~feof(fid)
        text=fgetl(fid);
        if contains(text,"RESPONSE")
            str=get_response_message(t_file);
            new_str=split(str,',');
            final_str=new_str(message_header_len+1:length(new_str));
            k=0;
            temp='';
            for i=1:length(final_str)    
                 k=k+1;    
                    if k>3
                        k=0;        
                        temp='';
                        continue;     
                    end
   
                temp=temp+string(final_str{i});   
                if strlength(temp)==6
                  dtc_codes=[dtc_codes temp];
                  temp='';
                end
            end
        end
    end  
    fclose(fid);
end


%Function for getting date
function date=getDate(filename)
    fid=fopen(filename,'r');
    while ~feof(fid)
        text=fgetl(fid);
        if contains(text,"RESPONSE")
            date=text(11:21);
            break;
        end        
    end
    fclose(fid);
end



%Function for getting Time
function time=getTime(filename)
    fid=fopen(filename,'r');    
    while ~feof(fid)
        text=fgetl(fid);
        if contains(text,"RESPONSE")
            time=text(22:33);
            break;
        end
    end
    fclose(fid);
end



%Function for unzipping files
function unzipping(filename,output_file)
    unzip(filename,output_file);    
end

%Function For .dat file
function dat_file=list_dat_file(output_file)
    file_pattern=fullfile(output_file,'*.DAT');
    res=dir(file_pattern);
    fin_file={res.name};
    dat_file=fin_file(1);     
end
%Function to get the list of .t0* files from directory
function t_files=list_t_files(output_file)
    file_pattern=fullfile(output_file,'*.t0*');
    t_files=[];
    res=dir(file_pattern);
    fin_res={res.name};
    for i=1:length(fin_res)
        t_files=[t_files fin_res(i)];
    end
end



%Function for Message Header Length
function l=message_header_length(file)
    fid=fopen(file,'r');
    while ~feof(fid)
        text=fgetl(fid);
        if contains(text,"REQUEST")
            for i=1:length(text)
                if strcmp("=",text(i))
                    str=text(i+1:length(text));
                    new_str=split(str,',');
                    l=length(new_str);
                    break;
                end
            end
            
        end
    end
    fclose(fid);
end



%Function for Response Code String
function l=get_response_message(t_file)
    fid=fopen(t_file);
    while ~feof(fid)
        text=fgetl(fid);
        if contains(text,"RESPONSE")
            len=length(text);
            for i=1:len
                if  strcmp("=",text(i))
                    l=text(i:len);
                    break;
                end
            end
        end
    end
    fclose(fid);
end
