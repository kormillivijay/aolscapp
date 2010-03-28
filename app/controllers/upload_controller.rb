require 'csv'

class UploadController < ApplicationController
  def index
  @courses = Course.find(:all)

  @coursesel = params[:coursesel]
  @teacherssel = params[:teacherssel]
  @assistantssel1 = params[:assistantssel1]

  @teacherusers = Role.find_by_role_name("Teacher").users
    @teachers = []
    @teacherusers.each do |tu|
       @teachers << tu.member
    end

    @assistantusers = Role.find_by_role_name("Volunteer").users
    @assistants = []
    @assistantusers.each do |tu|
       @assistants << tu.member
    end

  end

  def upload_file
    if params[:coursesel][:id].empty?
      flash[:notice] = 'Please select a course'
      redirect_to params.merge!(:action => :index)
    elsif params[:start_date].empty?
      flash[:notice] = 'Please choose a start date'
      redirect_to params.merge!(:action => :index)
    elsif params[:teacherssel][:id].empty?
      flash[:notice] = 'Please select a teacher'
      redirect_to params.merge!(:action => :index)
    elsif params[:assistantssel1][:id].empty?
      flash[:notice] = 'Please select an assistant'
      redirect_to params.merge!(:action => :index)
    elsif params[:upload].nil?
      flash[:notice] = 'Please select a file to upload'
      redirect_to params.merge!(:action => :index)
    else
      courseName = Course.find(params[:coursesel][:id]).name
      courseScheduleId = mycoursesched( params[:coursesel][:id],Time.parse(params[:start_date]).utc,params[:teacherssel][:id],params[:assistantssel1][:id] )
      puts "before "
      puts params[:start_date]
      puts "after "
      puts Time.parse(params[:start_date]).utc
      save(params[:upload], courseScheduleId, courseName)
      flash[:notice] = 'File has been uploaded successfully.'
    end
  rescue CustomException::WrongFileFormat
    flash[:notice] = 'The uploaded file does not belong to the Course chosen. Please verify.'
    redirect_to :action => "index"
  end

    def mycoursesched ( courseId,courseDate,teacherId, assistantId)
    @cs = CourseSchedule.find(:all, :conditions => ["start_date = ? and course_id=? and teacher_id=?", courseDate, courseId, teacherId])
    if @cs.empty?
      t =  Hash[
        'course_id',courseId,
        'start_date',courseDate,
        'teacher_id',teacherId,
        'volunteer_id',assistantId,
      ];
      @course_schedule = CourseSchedule.new(t)

      @course_schedule.save
      id = @course_schedule.id
      puts "created cs "
      return id
    else
      puts "returning " + @cs[0].id.to_s
      return @cs[0].id
    end
  end

  def save( upload, courseScheduleId, courseName )
    name = upload['datafile'].original_path
    dirictory = 'public/data'
    # create the file path
    path = File.join( dirictory, name )
    data = upload['datafile'].read;
    puts '************************************************'
    #puts data;
    puts '************************************************'
    File.open(path, "wb") { |f| f.write( data ) }

    createMembers(path, courseScheduleId, courseName)

    end
  end

  # Function to create members and maping members to course schedules
  ##
  def createMembers(path, courseScheduleId, courseName)
    if courseName.eql?("mbw")
      rowCount = 1
      CSV.open( path , 'r', ',') do |row|
        if rowCount == 1 and !row[1].equal?('Address1')
          raise CustomException::WrongFileFormat
        end

        if rowCount > 2
          if !row[0].nil? and !row[0].empty?
            t =  Hash[
              'firstname',row[0].split(' ')[0],
              'lastname',row[0].split(' ')[1],
              'address1',row[1],
              'address2',row[2],
              'city',row[3],
              'state',row[4],
              'zip',row[5],
              'country',row[6],
              'emailid',row[8],
              'homephone',row[9],
            ];
            @member = Member.new(t)

            if isExistingMember( @member )
              mapMemberToCourseSchedule(@member.id,courseScheduleId)
            else
              @member.save
              mapMemberToCourseSchedule(@member.id,courseScheduleId)
            end
         end
        end
        rowCount = rowCount +1
      end
    else if courseName.eql?("part1")
      rowCount = 1
      CSV.open( path , 'r', ',') do |row|
        if rowCount == 1 and !row[1].equal?('Gender')
          raise CustomException::WrongFileFormat
        end

        if rowCount > 2
          if !row[0].nil? and !row[0].empty?
            t =  Hash[
              'firstname',row[0].split(' ')[0],
              'lastname',row[0].split(' ')[1],
              'gender', row[1],
              'address1',row[2],
              'city',row[3],
              'state',row[4],
              'zip',row[5],
              'emailid',row[6],
              'homephone',row[23],
              'cellphone',row[25],
            ];
            @member = Member.new(t)

            if( isExistingMember( @member ) )
              mapMemberToCourseSchedule(@member.id,courseScheduleId)
            else
              @member.save
              mapMemberToCourseSchedule(@member.id,courseScheduleId)
            end
          end
        end
        rowCount = rowCount +1
      end
    end
    end
  end
  



  ##
  # Function to validate if member already exists.
  ##

  def isExistingMember( member )
    #Validate if member already exists

    @validatemember = Member.find(:all, :conditions => ["firstname = ? AND lastname = ? AND emailid = ?", member.firstname, member.lastname, member.emailid
      ])
    if @validatemember.length == 0
      return false
    else
       member.id = @validatemember[0].id
      return true
    end

  end

  ##
  # Function to map members to course schedule.
  ##
  def mapMemberToCourseSchedule(memberId,courseScheduleId)
    t =  Hash[
      'member_id',memberId,
      'course_schedule_id',courseScheduleId,
    ];
    @member_course = MemberCourse.new(t)
    @validatecoursescheduleid = MemberCourse.find(:all, :conditions => ["member_id=? and course_schedule_id = ?", @member_course.member_id, @member_course.course_schedule_id] )
    if @validatecoursescheduleid.length == 0 or @validatecoursescheduleid.empty?
      @member_course.save
    end
  end

  ##
  # Function to create Course scehdule
  ##

