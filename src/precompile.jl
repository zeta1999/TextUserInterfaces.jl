# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   Precompile statements.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function _precompile()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing

    # TUI
    # ==========================================================================

    @precompile destroy_tui

    # Focus manager
    # ==============================================================================

    @precompile process_focus Keystroke
    @precompile next_window
    @precompile previous_window
    @precompile request_focus Window

    # Inputs
    # ==============================================================================

    @precompile jlgetch Nothing
    @precompile jlgetch Ptr{WINDOW}

    # Logger
    # ==============================================================================

    @precompile log_message (LogLevels, String, String)

    # Objects
    # ==============================================================================

    @precompile compute_object_positioning (ObjectPositioningConfiguration, Window)
    @precompile compute_object_positioning (ObjectPositioningConfiguration, WidgetContainer)
    @precompile _get_anchor (Anchor, Window)
    @precompile _get_anchor (Anchor, WidgetContainer)
    @precompile _process_vertical_info! ObjectPositioningConfiguration
    @precompile _process_horizontal_info! ObjectPositioningConfiguration
    @precompile _str ObjectPositioningConfiguration

    # Widgets
    # ==============================================================================

    # Ansi labels
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:ansi_label}, WidgetContainer, ObjectPositioningConfiguration),
                (:alignment, :color, :text),
                (Symbol, Int, String))
    @precompile(change_text,
                (WidgetANSILabel, String),
                (:alignment, :color),
                (Symbol, Int))
    @precompile destroy_widget WidgetANSILabel :refresh Bool
    @precompile init_widget! WidgetANSILabel
    @precompile redraw WidgetANSILabel
    @precompile _destroy_widget WidgetANSILabel :refresh Bool

    # Button
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:button}, WidgetContainer, ObjectPositioningConfiguration),
                (:label, :color, :color_highlight, :style, :_derive),
                (String, Int, Int, Symbol, Bool))
    @precompile change_label (WidgetButton, String)
    @precompile destroy_widget WidgetButton :refresh Bool
    @precompile init_widget! WidgetButton
    @precompile redraw WidgetButton
    @precompile _destroy_widget WidgetButton :refresh Bool
    @precompile _draw_button (WidgetButton, Bool)

    # Container
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:container}, Window, ObjectPositioningConfiguration),
                (:border, :border_color, :composed, :title, :title_alignment,
                :title_color),
                (Bool, Int, Bool, String, Symbol, Int))
    @precompile redraw WidgetContainer
    @precompile destroy_widget WidgetContainer :refresh Bool
    @precompile init_widget! WidgetContainer
    @precompile _destroy_widget WidgetContainer :refresh Bool

    # Combo box
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:combo_box}, WidgetContainer, ObjectPositioningConfiguration),
                (:data, :color, :color_highlight, :list_box_border,
                 :list_box_color, :list_box_color_highlight, :style),
                (Vector{String}, Int, Int, Bool, Int, Int, Symbol))
    @precompile redraw WidgetComboBox
    @precompile destroy_widget WidgetComboBox :refresh Bool
    @precompile init_widget! WidgetComboBox
    @precompile _destroy_widget WidgetComboBox :refresh Bool
    @precompile _draw_combo_box WidgetComboBox
    @precompile _handle_input (WidgetComboBox, Keystroke)

    # Form
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:form}, WidgetContainer, ObjectPositioningConfiguration, Vector{String}),
                (:borders, :color_valid, :color_invalid, :field_size,
                 :validator),
                (Bool, Int, Int, Int, Nothing))
    @precompile(create_widget,
                (Val{:form}, WidgetContainer, ObjectPositioningConfiguration, Vector{String}),
                (:borders, :color_valid, :color_invalid, :field_size,
                 :validator),
                (Bool, Int, Int, Int, Vector{DataType}))

    # Input field
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:input_field}, WidgetContainer, ObjectPositioningConfiguration),
                (:border, :color_valid, :color_invalid, :max_data_size,
                 :validator, :parsed_data_sample),
                (Bool, Int, Int, Int, Nothing, Nothing))
    @precompile(create_widget,
                (Val{:input_field}, WidgetContainer, ObjectPositioningConfiguration),
                (:border, :color_valid, :color_invalid, :max_data_size,
                 :validator, :parsed_data_sample),
                (Bool, Int, Int, Int, DataType, Float32))
    @precompile(create_widget,
                (Val{:input_field}, WidgetContainer, ObjectPositioningConfiguration),
                (:border, :color_valid, :color_invalid, :max_data_size,
                 :validator, :parsed_data_sample),
                (Bool, Int, Int, Int, DataType, Float64))
    @precompile(create_widget,
                (Val{:input_field}, WidgetContainer, ObjectPositioningConfiguration),
                (:border, :color_valid, :color_invalid, :max_data_size,
                 :validator, :parsed_data_sample),
                (Bool, Int, Int, Int, DataType, Int))
    @precompile(create_widget,
                (Val{:input_field}, WidgetContainer, ObjectPositioningConfiguration),
                (:border, :color_valid, :color_invalid, :max_data_size,
                 :validator, :parsed_data_sample),
                (Bool, Int, Int, Int, DataType, String))

    # Label
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:label}, WidgetContainer, ObjectPositioningConfiguration),
                (:alignment, :color, :fill_color, :text),
                (Symbol, Int, Bool, String))
    @precompile destroy_widget WidgetLabel :refresh Bool
    @precompile init_widget! WidgetLabel
    @precompile redraw WidgetLabel
    @precompile _destroy_widget WidgetLabel :refresh Bool

    # List box
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:list_box}, WidgetContainer, ObjectPositioningConfiguration),
                (:data, :color, :color_highlight, :color_selected,
                 :multiple_selection, :numlines, :icon_not_selected,
                 :icon_selected, :selectable, :show_icon, :_derive),
                (Vector{String}, Int, Int, Int, Bool, Int, String, String, Bool,
                 Bool, Bool))
    @precompile destroy_widget WidgetListBox :refresh Bool
    @precompile init_widget! WidgetListBox
    @precompile redraw WidgetListBox
    @precompile _destroy_widget WidgetListBox :refresh Bool
    @precompile _handle_input (WidgetListBox, Keystroke)

    # Progress bar
    # ------------------------------------------------------------------------------

    @precompile(create_widget,
                (Val{:progress_bar}, WidgetContainer, ObjectPositioningConfiguration),
                (:border, :color, :color_highlight, :style, :value),
                (Bool, Int, Int, Symbol, Int))
    @precompile change_value (WidgetProgressBar, Int) :color Int
    @precompile destroy_widget WidgetProgressBar :refresh Bool
    @precompile init_widget! WidgetProgressBar
    @precompile redraw WidgetProgressBar
    @precompile _destroy_widget WidgetProgressBar :refresh Bool
    @precompile _draw_progress_bar_simple WidgetProgressBar
    @precompile _draw_progress_bar_complete WidgetProgressBar

    # Windows
    # ==============================================================================

    @precompile(create_window, (ObjectPositioningConfiguration, String),
                (:bcols, :blines, :border, :border_color, :focusable, :title,
                 :title_color),
                (Int, Int, Bool, Int, Bool, String, Int))
    @precompile destroy_window Window
    @precompile destroy_all_windows
    @precompile reposition! (Window, ObjectPositioningConfiguration) :force Bool
end
