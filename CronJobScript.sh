#!/bin/bash

#Replaces number with string for month and weekday
MonthWeekdayNumToString() {
    val="$1"

    if [ "$2" == "month" ]
    then
        case "$val" in 
            1)
                val="JAN";;
            2)
                val="FEB";;
            3)
                val="MAR";;
            4)
                val="APR";;
            5)
                val="MAY";;
            6)
                val="JUN";;
            7)
                val="JUL";;
            8)
                val="AUG";;
            9)
                val="SEP";;
            10)
                val="OCT";;
            11)
                val="NOV";;
            12)
                val="DEC";;
        esac
    elif [ "$2" == "weekday" ]
    then
        case "$val" in
            1)
                val="MON";;
            2)
                val="TUE";;
            3)
                val="WED";;
            4)
                val="THU";;
            5)
                val="FRI";;
            6)
                val="SAT";;
            7)
                val="SUN";;
        esac
    fi

    echo "$val"
}

#Translates a single time portion from a cron job to user friendly text
TranslateJobTime () {
    case $2 in
        1)
            timeCategory="minute"
            max=59;;
        2)
            timeCategory="hour"
            max=23;;
        3)
            timeCategory="day"
            max=31;;
        4)
            timeCategory="month"
            max=DEC;;
        5)
            timeCategory="weekday"
            max=SUN;;
    esac
    
    #Holds the number of values seperated by a ","
    valueNo=$(echo "$1" | tr "," "\n" | wc -l)
    
    #Steps through each value to convert them to readable text
    for i in $(seq 1 $valueNo)
    do
        #Cut current value from list of values 
        time="$(echo "$1" | cut -f$i -d ',')"
        
        #If there is a step (/), seperate from value
        if [[ "$time" == *"/"* ]]
        then
            step="$(echo "$time" | cut -f2 -d '/')"	
            time="$(echo "$time" | cut -f1 -d '/')"
            
            primaryString="every $step ${timeCategory}s" 
            
            secondaryString=" from $(MonthWeekdayNumToString $time $timeCategory) through $max"
        else   
            if [["$time" == *"*"*]] || [["$time" == *"-"*]]
            then
                primaryString="every $timeCategory"
            elif ["$timeCategory" == "month"] || ["$timeCategory" == "weekday"]
            then
                primaryString=""
            else
                primaryString="$timeCategory"
            fi
            
            if [["$time" == *"-"*]]
            then
                a=$(MonthWeekdayNumToString "$(echo "$time" | cut -f1 -d '-')" $timeCategory)
                b=$(MonthWeekdayNumToString "$(echo "$time" | cut -f2 -d '-')" $timeCategory)
                secondaryString=" from $a through $b"
            elif ["$time" == *"*"*]
            then
                secondaryString=""
            elif ["$timeCategory" == "month"] || ["$timeCategory" == "weekday"]
            then
                secondaryString="$(MonthWeekdayNumToString $time $timeCategory)"
            else
                secondaryString=" $(MonthWeekdayNumToString $time $timeCategory)"
            fi
        fi
        
        #primaryString holds time category (minute, hour etc.) plus extra text
        #secondaryString holds time value plus extra text
        fullString="$primaryString$secondaryString"
        
        #Only include 'and' after the first value
        if [ $i != 1 ]
        then
            completedTranslation="$completedTranslation and $fullString"
        else
            completedTranslation="$fullString"
        fi
    done
    
    echo "$completedTranslation"
}

#Takes a full cron job and translates it to user friendly text
TranslateJob () {   
    #If job uses a time preset
    if [[ "$1" == "@"* ]]
    then
        #Separate job between time and command sections
        time=$(echo "$1" | cut -f1 -d ' ')
        command=$(echo "$1" | cut -f2 -d ' ')
        
        case "$time" in
            "@yearly")
                echo -e "At the beginning of every year: \n$command";;
            "@annually")
                echo -e "At the beginning of every year: \n$command";;
            "@monthly")
                echo -e "At the beginning of every month: \n$command";;
            "@weekly")
                echo -e "At the beginning of every week: \n$command";;
            "@daily")
                echo -e "At the beginning of every day: \n$command";;
            "@hourly")
                echo -e "At the beginning of every hour: \n$command";;
            "@reboot")
                echo -e "After rebooting: \n$command";;
        esac
    else
        #Seperates each time section of the job	
        minute=$(echo "$1" | cut -f1 -d ' ')
        hour=$(echo "$1" | cut -f2 -d ' ')
        day=$(echo "$1" | cut -f3 -d ' ')
        month=$(echo "$1" | cut -f4 -d ' ')
        weekday=$(echo "$1" | cut -f5 -d ' ')
        
        #Joins the seperate time sections of the job back together
        time="$minute $hour $day $month $weekday "
        
        #Alters the time section of the job so that asterisks are correctly removed in the following line
        time=$(echo "$time" | sed "s:\*:\\\*:g")       
        #Uses the full time section of the job to find the command section
        command=$(echo "$1" | sed "s:^$time::g")
        
        echo "command: " $command
        
        #Echoes the full translation
        echo -e "At $(TranslateJobTime "$minute" 1) past $(TranslateJobTime "$hour" 2) on $(TranslateJobTime "$day" 3) in $(TranslateJobTime "$month" 4) on $(TranslateJobTime "$weekday" 5): \n$command"
    fi
}

#Changes a month or weekday string to the corresponding number
MonthWeekdayStringToNum() {
    val="$1"

    shopt -s nocasematch

    case "$val" in 
        jan)
            val=1;;
        feb)
            val=2;;
        mar)
            val=3;;
        apr)
            val=4;;
        may)
            val=5;;
        jun)
            val=6;;
        jul)
            val=7;;
        aug)
            val=8;;
        sep)
            val=9;;
        oct)
            val=10;;
        nov)
            val=11;;
        dec)
            val=12;;
    esac

    case "$val" in
        mon)
            val=1;;
        tue)
            val=2;;
        wed)
            val=3;;
        thu)
            val=4;;
        fri)
            val=5;;
        sat)
            val=6;;
        sun)
            val=7;;
    esac
    
    shopt -u nocasematch

    echo "$val"
}

#Validates the user input of a single time section for a new cron job
ValidateTimeSection() {
    #Takes a single time section from a job and validates it
    #$1 = users input, $2 = time category (minute, hour, day etc.)
    
    #Assigns the max based on the time section
    case $2 in
        1)
            max=59;; #Minute
        2)
            max=23;; #Hour
        3)
            max=31;; #Day
        4)
            max=12;; #Month
        5)
            max=7;; #Week
    esac

    #Empty input
    if [ "$1" == "" ]
    then
        echo "Input was blank"
        return 
    fi

    #Removes all valid characters to check that no invalid characters are present
    minusValidChars=$(echo "$1" | sed -e "s:[0-9]::g" -e "s:/::g" -e "s:-::g" -e "s:*::g" -e "s:,::g")
    
    #Accounts for the use of a string to specify a specific month or weekday
    if [ $2 == 4 ] #Month
    then
        minusValidChars=$(echo "$minusValidChars" | sed -e "s:jan::gI" -e "s:feb::gI" -e "s:mar::gI" -e "s:apr::gI" -e "s:may::gI" -e "s:jun::gI" -e "s:jul::gI" -e "s:aug::gI" -e "s:sep::gI" -e "s:oct::gI" -e "s:nov::gI" -e "s:dec::gI")
    elif [ $2 == 5 ] #Weekday
    then
        minusValidChars=$(echo "$minusValidChars" | sed -e "s:mon::gI" -e "s:tue::gI" -e "s:wed::gI" -e "s:thu::gI" -e "s:fri::gI" -e "s:sat::gI" -e "s:sun::gI")
    fi

    #Any remaining characters are invalid
    if [ "$minusValidChars" != "" ]
    then
        echo "Input contained invalid characters"
        return 
    fi

    #Holds the number of values seperated by a ","
    valueNo=$(echo "$1" | tr "," "\n" | wc -l)

    #Loops through all comma separated values
    for i in $(seq 1 $valueNo)
    do
        #Create raw value from list of values 
        time="$(echo "$1" | cut -f$i -d ',')"
        
        if [ "$time" == "" ]
        then
            echo "A value for one or more parameters was formatted incorrectly"
            return 
        fi

        #Check there are no more than one "/", "-" or "*"
        if [ $(echo "$time" | tr "/" "\n" | wc -l) -gt 2 ] || 
           [ $(echo "$time" | tr "-" "\n" | wc -l) -gt 2 ] || 
           [ $(echo "$time" | tr "*" "\n" | wc -l) -gt 2 ]
        then
            echo "One or more parameters were formatted incorectly"
            return 
        fi
        
        #If the value uses a step
        if [[ "$time" == *"/"* ]]
        then
            step="$(echo "$time" | cut -f2 -d '/')"
            time="$(echo "$time" | cut -f1 -d '/')"
            
            #Check that the step portion is not empty
            if [ "$step" == "" ]
            then
                echo "A step section for one of more parameters was formatted incorrectly"
                return 
            fi
            
            if [[ "$step" == 0 ]]
            then
                echo "A step section for one of more parameters was formatted incorrectly"
                return 
            fi
            
            #Check that the step portion only contains digits
            stepCheck=$(echo "$step" | sed "s:[0-9]::g")

            if [ "$stepCheck" != "" ] 
            then
                echo "A step section for one of more parameters was formatted incorrectly"
                return 
            fi
                    
            #If value does not contain an astersisk and is not a range
            if [[ "$time" != "*" && "$time" != *"-"* ]]
            then
                #Translates valid text to numbers
                time="$(MonthWeekdayStringToNum "$time")"
            
                let "dif = $max - $time"

                #Check that step is valid with range
                if [ $step -gt $dif ]
                then
                    echo "A step section for one of more parameters was formatted incorrectly"
                    return 
                fi
            fi
        fi
        
        if [[ "$time" == *"-"* ]]
        then
            #Check that range portion does not contain asterisks
            if [[ "$time" == *"*"* ]]
            then
                echo "A range of values for one or more parameters was formatted incorrectly"
                return 
            fi
                
            #Cut min of range
            a="$(echo $time | cut -f1 -d '-')"
            #Translate valid text to numbers
            a="$(MonthWeekdayStringToNum "$a")"
                
            #Cut max of range
            b="$(echo $time | cut -f2 -d '-')"
            #Translate valid text to numbers
            b="$(MonthWeekdayStringToNum "$b")"

            #Check that neither side of range is blank
            if [ "$a" == "" ] || [ "$b" == "" ]
            then
                echo "A range of values for one or more parameters was formatted incorrectly"
                return 
            fi

            #Check that range values are in correct order
            if [ "$a" -gt "$b" ]
            then
                echo "A range of values for one or more parameters was formatted incorrectly"
                return 
            fi

            #Check that range values are below max
            if [ $a -gt $max ] || [ $b -gt $max ]
            then
                echo "A range of values for one or more parameters was formatted incorrectly"
                return 
            fi
                
            #If input contained a step
            if [ "$step" != "" ]
            then
                let "dif = $b - $a"

                #Check that step is valid with range
                if [ $step -gt $dif ]
                then
                    echo "A step section for one of more parameters was formatted incorrectly"
                    return 
                fi
            fi
        else
            #Translate valid text to numbers
            time="$(MonthWeekdayStringToNum "$time")"
            
            if [[ "$time" == *"*"* ]]
            then
                return
            fi
            
            if [ $time -gt $max ]
            then
                echo "A value for one or more parameters was formatted incorrectly"
                return 
            fi
        fi	
    done
}

#Takes the users input for each component of the cron job and compiles it into the full job string
CreateJob() {
    
    echo -e "Choose a preset or enter a specific periodicity?\n"
    echo -e "1. Preset"
    echo -e "2. Custom\n"

    #Validate input
    while true
    do	
        read -p "Choose one of the above: " choice
        if [ $choice == 1 ] || [ $choice == 2 ]
        then
            break;
        else
            echo -e "Please choose a valid option\n"
        fi
    done

    if [ $choice == 1 ]
    then
        echo "1. Hourly"
        echo "2. Daily"
        echo "3. Weekly"
        echo "4. Monthly"
        echo "5. Yearly"
        echo "6. At Reboot"
        echo -e "\n"

        while true
        do
            read -p "Choose one of the above: " preset
            if [ $preset == 1 ] || [ $preset == 2 ] || [ $preset == 3 ] || 
               [ $preset == 4 ] || [ $preset == 5 ] || [ $preset == 6 ]
            then
                break;
            else
                echo -e "Please choose a valid option\n"
            fi
        done
        
        case $preset in
            1)
                time="@hourly";;
            2)
                time="@daily";;
            3)
                time="@weekly";;
            4)
                time="@monthly";;
            5)
                time="@yearly";;
            6)
                time="@reboot";;
        esac
    else
        #Each time category loops to check that the users input is correctly formatted
        while true
        do
            read -p "Enter minute frequency: " minute
            
            #Determine if input was a valid time for "minute" section
            error=$(ValidateTimeSection "$minute" "1") 
            
            if [ "$error" == "" ] #If no error
            then
                break;
            else	
                echo "$error"
            fi
        done
        while true
        do
            read -p "Enter hour frequency: " hour
            error=$(ValidateTimeSection "$hour" "2")
            if [ "$error" == "" ]
            then
                break;
            else
                echo "$error"
            fi
        done
        while true
        do	
            read -p "Enter day frequency: " day
            error=$(ValidateTimeSection "$day" "3")
            if [ "$error" == "" ]
            then
                break;
            else
                echo "$error"
            fi
        done
        while true
        do
            read -p "Enter month frequency: " month
            error=$(ValidateTimeSection "$month" "4")
            if [ "$error" == "" ]
            then
                break;
            else
                echo "$error"
            fi
        done
        while true
        do
            read -p "Enter weekday frequency: " weekday
            error=$(ValidateTimeSection "$weekday" "5")
            if [ "$error" == "" ]
            then
                break;
            else
                echo "$error"
            fi
        done

        time="$minute $hour $day $month $weekday"
    fi
    
    read -p "Enter command to run: " command
    
    job="$time $command"

    TranslateJob "$job"

    echo -e "\n"
    
    read -p "Create the following new job?(y/n): " choice
    
    #Checks the choice input and if it was valid
    while true
    do
        if [ "$choice" == "y" ]
        then
            (crontab -l; echo "$job") | crontab -
            break;
        elif [ "$choice" == "n" ]
        then
            break;
        else
            read -p "Please enter a valid choice(y/n): " choice
        fi
    done
}

#Shows the jobs in the crontab file in a user friendly format
ShowingJobWithText()
{
    cronOnlyJobs=$(crontab -l | grep -v '^#' | grep -v '^$')
    
    #Ends early if the crontab file is empty
    if [ "$cronOnlyJobs" == "" ]
    then
        return 1 
    fi
    
    #For a sequence starting at 1 and ending at the number of lines in cronOnlyJobs
    for i in $(seq 1 $(echo "$cronOnlyJobs" | wc -l))
    do
        #Take the ith field, using '\n' as a delimiter, therefore separating by line
        job=$(echo "$cronOnlyJobs" | cut -f$i -d$'\n')
        
        translated=$(TranslateJob "$job") #Translates a job to readable text
        echo -e "$i. $translated\n"
    done
}

#Effectively removes a job and creates a new job simultaneously
EditJob()
{
    echo "Choose a job to Edit: "
    read jobToEdit
    
    #Contains only the line with the specified job
    editingJob=$(crontab -l | grep -v '^#' | grep -v '^$' | sed "${jobToEdit}!d")
    
    TranslateJob "$editingJob"
    
    echo -e "\n"
    echo "Rewrite this job? (y/n)"
    read yesOrNo
    echo -e "\n"
    
    if [ $yesOrNo == "y" ]
    then
        #Overrites crontab file with copy not including chosen job
        crontab -l | grep -v '^#' | grep -v '^$' | sed "${jobToEdit}d" | crontab - 

        CreateJob
        
        echo "Job edit succesful"
    elif [ $yesOrNo == "n" ]
    then
        echo ""	
    else
        echo "Invalid Selection"
    fi
}

#Main Loop
while true
do
    echo "1. Display crontab jobs"
    echo "2. Insert a Job"
    echo "3. Edit a Job"
    echo "4. Remove a Job"
    echo "5. Remove all Jobs"	
    echo "9. Exit"
    echo ""
    read -p "Choose an option: " chosenOption
    
    echo "Option Chosen: $chosenOption"
    
    echo -e "\n"
    
case $chosenOption in
    1)
        echo "Current Cronjobs: "
        echo -e "\n"
        
        #Lists all jobs in the crontab file in a readable format
        ShowingJobWithText
        
        if [ $? == 1 ] #If there are no jobs in the crontab file
        then
            echo "There are no jobs to display"
            echo -e "\n"
        fi;;
    2)
        CreateJob;;
    3)
        ShowingJobWithText
        if [ $? == 1 ]
        then
            echo "There are no jobs to edit"
            echo -e "\n"
        else
            EditJob
        fi;;
    4)
        ShowingJobWithText
        
        if [ $? == 1 ]
        then
            echo "There are no jobs to remove"
            echo -e "\n"
        else
            read -p "Enter the number of the job you wish to remove: " jobToRemove
            echo -e "\n"
            
            #Takes content of crontab file, removes selected job, 
            #and replaces crontab file with new content
            $(crontab -l | grep -v '^#' | grep -v '^$' | sed "${jobToRemove}d" | crontab -)
            
            ShowingJobWithText
            
            if [ $? == 1 ]
            then
                echo "There are no more jobs"
            fi
        fi;;
    5)	
        crontab -r | crontab -
        
        echo "All jobs have been removed"
        echo -e "\n";;
    9)
        exit 0
esac
done