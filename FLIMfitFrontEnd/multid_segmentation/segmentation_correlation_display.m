classdef segmentation_correlation_display < handle
    
    properties
       parent;
       controller; 
       
       panel;
       ax;
       im;
       
       mask;
       circle_h;
       
       x_listbox;
       y_listbox;
       
       x_min_edit;
       x_max_edit;
       y_min_edit;
       y_max_edit;
       
       x_data;
       y_data;
       
       tool_roi_circle_toggle;
       tool_roi_rect_toggle; 
       tool_roi_poly_toggle;
       toggle_active;
       flex_h;
    end
            
    methods
       
        function obj = segmentation_correlation_display(controller,parent)
            obj.parent = parent;
            obj.controller = controller;
            
            obj.setup_layout();
            obj.update();
        end
        
        function info = get_info(obj)
            info.x_name = obj.x_listbox.String{obj.x_listbox.Value};
            info.y_name = obj.y_listbox.String{obj.y_listbox.Value};
            
            if ~isempty(obj.flex_h) && isvalid(obj.flex_h)
                info.flex_type = class(obj.flex_h);
                info.flex_pos = obj.flex_h.getPosition();
            else
                info.flex_type = 'none';
                info.flex_pos = [];
            end
        end
        
        function set_info(obj,info)
            
            x_idx = find(strcmp(obj.x_listbox.String, info.x_name),1);
            y_idx = find(strcmp(obj.y_listbox.String, info.y_name),1);
            
            if ~isempty(x_idx)
                obj.x_listbox.Value = x_idx;
            end
            if ~isempty(y_idx)
                obj.y_listbox.Value = y_idx;
            end
            
            obj.update();

            delete(obj.flex_h)
            if ~strcmp(info.flex_type,'none') && ~isempty(x_idx) && ~isempty(y_idx)
                obj.flex_h = eval([info.flex_type '(obj.ax,info.flex_pos)']);
                obj.flex_h.addNewPositionCallback(@obj.roi_callback);
                obj.roi_callback();
            end
                        
        end
        
        function setup_layout(obj)
            
            labels = fieldnames(obj.controller.dataset);
            
            
            obj.panel = uipanel('Parent',obj.parent);
            display_layout = uix.VBox('Parent',obj.panel);
            
            % Limits layout
            lims_layout = uix.HBox('Parent',display_layout);
            uicontrol(lims_layout,'Style','text','String','x');
            obj.x_min_edit = uicontrol(lims_layout,'Style','edit','String','0');
            uicontrol(lims_layout,'Style','text','String','-');
            obj.x_max_edit = uicontrol(lims_layout,'Style','edit','String','0');
            uix.Empty('Parent',lims_layout);
            uicontrol(lims_layout,'Style','text','String','y');
            obj.y_min_edit = uicontrol(lims_layout,'Style','edit','String','0');
            uicontrol(lims_layout,'Style','text','String','-');
            obj.y_max_edit = uicontrol(lims_layout,'Style','edit','String','0');
            lims_layout.Widths = [20 -1 20 -1 -4 20 -1 20 -1];
            
            % Axes
            obj.ax = axes('Parent',display_layout);
            set(obj.ax,'Units','normalized','Position',[0 0 1 1]);

            % Control Layout
            control_layout = uix.HBox('Parent',display_layout);
            
            icons = load('icons.mat');
            obj.tool_roi_rect_toggle = uicontrol(control_layout,'Style','togglebutton','CData',icons.rect_icon,'ToolTipString','Rectangle','Callback',@obj.toggle_callback);
            obj.tool_roi_poly_toggle = uicontrol(control_layout,'Style','togglebutton','CData',icons.poly_icon,'ToolTipString','Polygon','Callback',@obj.toggle_callback);
            obj.tool_roi_circle_toggle = uicontrol(control_layout,'Style','togglebutton','CData',icons.ellipse_icon,'ToolTipString','Ellipse','Callback',@obj.toggle_callback);  
            
            obj.x_listbox = uicontrol(control_layout,'Style','popupmenu','String',labels,'Callback',@obj.update);
            obj.y_listbox = uicontrol(control_layout,'Style','popupmenu','String',labels,'Value',2,'Callback',@obj.update);
            uicontrol(control_layout,'Style','pushbutton','String','-','Callback',@obj.remove);
            uicontrol(control_layout,'Style','pushbutton','String','+','Callback',@obj.add);
            control_layout.Widths = [30 30 30 -1 -1 30 30];
            display_layout.Heights = [22 -1 22];

            obj.im = image(0,'Parent',obj.ax);            
            edges = linspace(0,1,256);
            ed = edges(2:255);
            obj.im = imagesc(ed,ed,ones(256,256),'Parent',obj.ax);
            daspect(obj.ax,[1 1 1])
            set(obj.ax,'YDir','normal','XTick',[],'YTick',[]);
            
            hold(obj.ax,'on');
            theta = linspace(0,pi,1000);
            c = 0.5*(cos(theta) + 1i * sin(theta)) + 0.5;
            obj.circle_h = plot(obj.ax,real(c), imag(c) ,'w');
            
            
            n_panel = length(obj.parent.Children);
            n_x = ceil(sqrt(n_panel));
            n_y = ceil(n_panel / n_x);
            obj.parent.Heights = -1 * ones(1,n_x);
            obj.parent.Widths = -1 * ones(n_y,1);
            
        end 
        
        function data = get_data(obj,name)
            data = obj.controller.dataset.(name);
                        
            switch name
                case 'intensity'
                    data = log10(data);
                    data = data / 4;
                case 'acceptor'
                    data = log10(data);
                    data = data / 4;
                case 'phasor_lifetime'
                    data = data / 12;
            end
            
            data(data > 1) = 1;
        end
        
        function update(obj,~,~)
            
            if ~isvalid(obj)
                return
            end
            
            x_name = obj.x_listbox.String{obj.x_listbox.Value};
            y_name = obj.x_listbox.String{obj.y_listbox.Value};
            
            obj.x_data = obj.get_data(x_name);
            obj.y_data = obj.get_data(y_name);
            
            I = obj.controller.dataset.intensity;

            pc = [obj.y_data(:) obj.x_data(:)];        
            n = histwv2(pc,I(:),0,1,256);
            n = n(2:255,2:255);
            %n(:,:,i) = ni; % / prctile(ni(:),99.9);
            %n = flip(n,3); % BGR -> RGB

            n = n / prctile(n(:),99.9);
            n(n>1) = 1;
            set(obj.im,'CData',n);
            
            if strcmp(x_name,'p_r') && strcmp(y_name,'p_i')
                obj.circle_h.Visible = 'on';
            else
                obj.circle_h.Visible = 'off';
            end
           
            obj.compute_mask();
        end
        
        function toggle_callback(obj,src,~)
            toggles = [obj.tool_roi_rect_toggle 
               obj.tool_roi_poly_toggle
               obj.tool_roi_circle_toggle];
            toggle_fcn = {@imrect,@impoly,@imellipse};
            
            if src.Value == 1
                delete(obj.flex_h);
                set(toggles(toggles ~= src),'Value',0);

                toggle_idx = find(toggles == src,1);
                toggle_fcn = toggle_fcn{toggle_idx};
                obj.flex_h = toggle_fcn(obj.ax);
                obj.flex_h.addNewPositionCallback(@obj.roi_callback);
                if toggle_idx ~= 2 % not poly
                    obj.flex_h.setResizable(true);
                end
                obj.toggle_active = src;
                obj.roi_callback();
            else
                if obj.toggle_active == src && ~isempty(obj.flex_h)
                    delete(obj.flex_h)
                end
            end            
        end
        
        function compute_mask(obj)           
            if ~isempty(obj.flex_h) && isvalid(obj.flex_h)
               pos = obj.flex_h.getPosition();
               sel = zeros(size(obj.x_data));
               flex_type = class(obj.flex_h);
               switch flex_type
                   case 'imrect'
                        sel = obj.x_data >= pos(1) & obj.x_data <= (pos(1) + pos(3)) & ...
                              obj.y_data >= pos(2) & obj.y_data <= (pos(2) + pos(4));
                   case 'imellipse'
                       rx = pos(3) / 2;
                       ry = pos(4) / 2;
                       cx = pos(1) + rx;
                       cy = pos(2) + ry;
                       sel = (((obj.x_data - cx) / rx).^2 + ((obj.y_data - cy) / ry).^2) < 1;
                   case 'impoly'
                       sel = inpolygon(obj.x_data,obj.y_data,pos(:,1),pos(:,2));
               end
               
               obj.mask = sel;
            end
        end
            
        function roi_callback(obj,~,~)
            obj.compute_mask();
            obj.controller.update_display();
            
        end
        
        function add(obj,~,~)
            obj.controller.add_correlation();
        end
        
        function remove(obj,~,~)
            if isvalid(obj)
                delete(obj.panel);
                delete(obj);
            end
        end
        
    end
    
end