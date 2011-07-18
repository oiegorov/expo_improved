MARKER_RUNNING = 4
MARKER_TERMINATED = 5
MARKER_ERROR = 6
EXPE_VIEW_STATE = {'R' => 'RUNNING', 't' => 'TERMINATING', 'T' => 'TERMINATED', 'E' => 'ERROR', 'L' => 'LOADED'}

# An ExpeView object is associate to an experiment to manage all its viewing/displaying aspects
class ExpeView
  attr_reader :task_list,:expe_program,:expe_stdeo, :notebook_index  
	def initialize(gui,expe_id,program)
		@gui = gui
		@expe_id = expe_id
		@notebook_index = @gui.notebook.get_page_count
		@expe_program = @gui.create_expe_program(expe_id,program)
		
		@task_list = @gui.create_task_list_pane(expe_id)
		@expe_stdeo =  @gui.create_expe_stdeo_pane(expe_id)

		@gui.expe_ctrl_view.list_box_expe_ctrl.append(expe_id,expe_id)

	end

	def show
		$expe_list[@gui.current_expe_view].view.hide  if !@gui.current_expe_view.nil?

		@gui.mgr.get_pane("task_list_#{@expe_id}").show(true)
		@gui.mgr.get_pane("expe_stdeo_#{@expe_id}").show(true)


		@gui.expe_ctrl_view.list_box_expe_ctrl.set_selection(@notebook_index-1)
		@gui.notebook.set_selection(@notebook_index)

		@gui.expe_ctrl_view.show(@expe_id)

		@gui.current_expe_view = @expe_id

		
		@gui.mgr.update

	end

	def hide
		@gui.mgr.get_pane("task_list_#{@expe_id}").show(false)
		@gui.mgr.get_pane("expe_stdeo_#{@expe_id}").show(false)
	end
end



class WxExpeProgram < Wx::StyledTextCtrl

	def initialize(parent,program)
		super(parent, Wx::ID_ANY, Wx::Point.new(0, 0), Wx::Size.new(150, 90), Wx::NO_BORDER|Wx::TE_MULTILINE)

		font = Wx::Font.new(10, Wx::TELETYPE, Wx::NORMAL, Wx::NORMAL)
    style_set_font(Wx::STC_STYLE_DEFAULT, font);

    @ws_visible = false
    @eol_visible = false
    set_edge_mode(Wx::STC_EDGE_LINE)

    line_num_margin = text_width(Wx::STC_STYLE_LINENUMBER, "_99999")
    set_margin_width(0, line_num_margin)

    style_set_foreground(Wx::STC_STYLE_DEFAULT, Wx::BLACK);
    style_set_background(Wx::STC_STYLE_DEFAULT, Wx::WHITE);
    style_set_foreground(Wx::STC_STYLE_LINENUMBER, Wx::LIGHT_GREY);
    style_set_background(Wx::STC_STYLE_LINENUMBER, Wx::WHITE);
    style_set_foreground(Wx::STC_STYLE_INDENTGUIDE, Wx::LIGHT_GREY);

    set_tab_width(4)
    set_use_tabs(false)
    set_tab_indents(true)
    set_back_space_un_indents(true)
    set_indent(4)
    set_edge_column(80)

    set_lexer(Wx::STC_LEX_RUBY)
    style_clear_all
    style_set_foreground(2, Wx::LIGHT_GREY)
    style_set_foreground(3, Wx::GREEN)
    style_set_foreground(5, Wx::BLUE)
    style_set_foreground(6, Wx::Colour.new(123,12,45))
    style_set_foreground(7, Wx::RED)
    set_key_words(0, "begin break elsif module retry unless end case next return until class ensure nil self when def false not super while alias defined? for or then yield and do if redo true else in rescue undef ptask task")
 set_key_words(3, "$all")


    set_property("fold","1")
    set_property("fold.compact", "0")
    set_property("fold.comment", "1")
    set_property("fold.preprocessor", "1")

    set_margin_width(1, 0)
    set_margin_type(1, Wx::STC_MARGIN_SYMBOL)
    set_margin_mask(1, Wx::STC_MASK_FOLDERS)
    set_margin_width(1, 20)

    marker_define(Wx::STC_MARKNUM_FOLDER, Wx::STC_MARK_PLUS)
    marker_define(Wx::STC_MARKNUM_FOLDEROPEN, Wx::STC_MARK_MINUS)
    marker_define(Wx::STC_MARKNUM_FOLDEREND, Wx::STC_MARK_EMPTY)
    marker_define(Wx::STC_MARKNUM_FOLDERMIDTAIL, Wx::STC_MARK_EMPTY)
    marker_define(Wx::STC_MARKNUM_FOLDEROPENMID, Wx::STC_MARK_EMPTY)
    marker_define(Wx::STC_MARKNUM_FOLDERSUB, Wx::STC_MARK_EMPTY)
    marker_define(Wx::STC_MARKNUM_FOLDERTAIL, Wx::STC_MARK_EMPTY)
    set_fold_flags(16)

    set_margin_sensitive(1,1)

	  set_margin_width(2, 0)
    set_margin_type(2, Wx::STC_MARGIN_SYMBOL)
    set_margin_mask(2, 0xFFFF)
	  set_margin_width(2, 20)


		marker_define(MARKER_RUNNING , 4,Wx::BLACK,Wx::BLUE)
    marker_define(MARKER_TERMINATED, 3,Wx::BLACK,Wx::GREEN)
	  marker_define(MARKER_ERROR, 3,Wx::BLACK,Wx::RED)

		append_text(program)

	end
end

class  WxTaskList < Wx::ListCtrl
#	@action_list = []
	def initialize(parent)
  	super(parent,  Wx::ID_ANY, Wx::DEFAULT_POSITION, Wx::Size.new(186, 250), Wx::LC_REPORT | Wx::LC_VIRTUAL | Wx::LC_HRULES | Wx::LC_VRULES)
	@action_list = []

		@blue_progress_bar = []
		@green_progress_bar = []
		@red_progress_bar = []

		@progress_il = Wx::ImageList.new(44,16)

		progress_bar_images(@blue_progress_bar,'blue')
		progress_bar_images(@green_progress_bar,'green')
		progress_bar_images(@red_progress_bar,'red')
		
		set_image_list(@progress_il, Wx::IMAGE_LIST_SMALL)
        
    insert_column(0,"Id")
    insert_column(1,"Type")
    insert_column(2,"Status")
    set_column_width(0,50)
    set_column_width(1,70)
    set_column_width(2,50)
        
    set_item_count(10000)
        
    @attr = Wx::ListItemAttr.new()
    @attr.set_background_colour(Wx::Colour.new("LIGHT GRAY"))
        
    evt_list_item_selected(get_id()) {|event| on_item_selected(event)}
    evt_list_item_activated(get_id()) {|event| on_item_activated(event)}
    evt_list_item_deselected(get_id()) {|event| on_item_deselected(event)}

	end


	def action_list
		return @action_list
	end

	def on_item_selected(event)
    @currentItem = event.get_index()
    @item = event.get_item()
    get_column(1,@item)
  end
    
  def on_item_activated(event)
     @currentItem = event.get_index()
  end
    
  def on_item_deselected(event)
  end
   
  # These three following methods are callbacks for implementing the
  # "virtualness" of the list; they *must* be defined by any ListCtrl
  # object with the style LC_VIRTUAL.

  # Normally you would determine the text, attributes and/or image
  # based on values from some external data source, but for this demo
  # we'll just calculate them based on order. 

	def on_get_item_text(item, col)
		if @action_list[item].nil?
			return '' 
		else
  		return @action_list[item][col].to_s
		end
  end
    
	def on_get_item_column_image(item, col)
		if @action_list[item].nil?
			return -1
		elsif col == A_PROGRESS
			case @action_list[item][A_STATE]
			when TERMINATED
				return @green_progress_bar[@action_list[item][A_PROGRESS]]
			when ERROR
				return @red_progress_bar[@action_list[item][A_PROGRESS]]
			else
				return @blue_progress_bar[@action_list[item][A_PROGRESS]]
			end
		else
			return -1
		end
	end
    
  def on_get_item_attr(item)
    if item % 2 == 0
      return @attr
    else
      return nil
    end
  end


private
	def progress_bar_images(progress_bar,color)
		0.upto(20) do |i|
			file = File.join(File.dirname(__FILE__),"progressbar_icons/pgb_#{color}_#{5*i}.png")
			id = @progress_il.add(Wx::Bitmap.new(file))
			0.upto(4) { |j| progress_bar[5*i+j] = id }
		end				
	end

end

#class  WxExpeStdeo < Wx::ListCtrl
#	def inialize(parent)
#		Wx::TextCtrl.new( parent, Wx::ID_ANY, "Waiting for experiment ouputs", Wx::Point.new(0, 0), Wx::Size.new(150, 90),Wx::NO_BORDER|Wx::TE_MULTILINE)
#	end
#end

class ExpeCtrlView
	attr_accessor :expe_ctrl, :list_box_expe_ctrl
	def initialize(gui)
		@gui = gui
		xml = Wx::XmlResource.get();
    xml.init_all_handlers();
 		xrc_file = File.join( File.dirname( __FILE__ ), 'expe_ctrl.xrc' )
		xml.load(xrc_file)	
		@expe_ctrl = xml.load_panel(@gui,'panel_expe_ctrl')

	 finder = lambda do | x | 
      int_id = Wx::xrcid(x)
      begin
        Wx::Window.find_window_by_id(int_id, @gui) || int_id
      # Temporary hack to work around regression in 1.9.2; remove
      # begin/rescue clause in later versions
      rescue RuntimeError
        int_id
      end
    end
    
    @panel_expe_ctrl = finder.call("panel_expe_ctrl")
    @panel_5 = finder.call("panel_5")
    @list_box_expe_ctrl = finder.call("list_box_expe_ctrl")
    @static_line_1 = finder.call("static_line_1")
    @panel_1 = finder.call("panel_1")
    @label_7 = finder.call("label_7")
    @text_expe_name = finder.call("text_expe_name")
    @label_8 = finder.call("label_8")
    @text_expe_description = finder.call("text_expe_description")
    @label_9 = finder.call("label_9")
    @text_expe_filename = finder.call("text_expe_filename")
		@text_expe_options = finder.call("text_expe_options")
    @static_line_2 = finder.call("static_line_2")
    @panel_4 = finder.call("panel_4")
    @static_line_3_copy = finder.call("static_line_3_copy")
    @button_expe_run = finder.call("button_expe_run")
    @button_expe_stop = finder.call("button_expe_stop")
    @button_expe_kill = finder.call("button_expe_kill")
		@expe_gauge = finder.call("expe_gauge")
	 	@expe_state_label = finder.call("expe_state_label")
	 	@expe_duration = finder.call("expe_duration")

		@gui.evt_listbox(@list_box_expe_ctrl.get_id){|event| on_evt_listbox(event)}

 		@gui.evt_button(@button_expe_run.get_id) {|event| on_click_run(event)}
		@gui.evt_button(@button_expe_stop.get_id) {|event| on_click_stop(event)}
		@gui.evt_button(@button_expe_kill.get_id) {|event| on_click_kill(event)}

	end

	def update_expe_state
		
		expe = $expe_list[@gui.current_expe_view]

		if !expe.nil? 
	
			puts "#{expe.id} state: #{EXPE_VIEW_STATE[expe.state]}" if !expe.nil? 

			@expe_state_label.set_label(EXPE_VIEW_STATE[expe.state]) 

			if expe.state == RUNNING
				expe.duration = (Time.now - expe.start).to_i
				expe.gauge = (100 * expe.action_list.last[A_LINE].to_f/expe.nb_lines.to_f).to_i if !expe.action_list.last.nil?
			end

			expe.gauge = 100 if expe.state == TERMINATED

			d = expe.duration 
			h = (d/3600).to_s
			h = "0"+h if h.length==1
			m = (d/60).to_s
			m = "0"+m if m.length==1
			s = (d%60).to_s
			s = "0"+s if s.length==1

			@expe_duration.set_label("#{h}:#{m}:#{s}")
			@expe_gauge.value = expe.gauge 
		end
	end

	def  show(expe_id)
		expe = $expe_list[expe_id]
		@text_expe_name.set_value(expe.id)
		@text_expe_description.set_value(expe.description) 
		@text_expe_filename.set_value(expe.file)
		@text_expe_options.set_value(expe.options) if !expe.options.nil?
		@expe_state_label.set_label(EXPE_VIEW_STATE[expe.state])
#		@expe_gauge = finder.call("expe_gauge")
		update_expe_state

	end

	def on_evt_listbox(event)
		puts 'yop'
		puts "evt_listbox: #{event.get_string}, #{event.is_selection}, #{event.get_selection}, #{event.get_client_data}"
		$expe_list[event.get_client_data].view.show
	end

	def on_click_run(event)
		expe = $expe_list[@gui.current_expe_view]
		puts "Click on Run: #{expe.id}"
		$expo_client.run(expe.id)
	end

	def on_click_stop(event)
		expe = $expe_list[@gui.current_expe_view]
		puts "Click on Stop #{expe.id}"	
		$expo_client.stop(expe.id)

	end

	def on_click_kill(event)	
		expe = $expe_list[@gui.current_expe_view]
		puts "Click on Kill #{expe.id}"
		$expo_client.kill(expe.id)
	end
end
