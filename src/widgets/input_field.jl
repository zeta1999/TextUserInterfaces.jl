# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   Widget: Input field.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export WidgetInputField, clear_data!, get_data

################################################################################
#                                     Type
################################################################################

@widget mutable struct WidgetInputField{P}
    # Data array that contains the input to the field.
    data::Vector{Char} = Char[]

    # Position of the physical cursor in the field.
    cury::Int  = 1
    curx::Int  = 1

    # Maximum allowed data size.
    max_data_size::Int = 0

    # Field usable size in screen.
    size::Int = 0

    # Position of the virtual cursor in the data array.
    vcury::Int = 1
    vcurx::Int = 1

    # Index of the first character in the data vector to be printed.
    view::Int = 1

    # Styling
    # =======

    border::Bool = false
    color_valid::Int = 0
    color_invalid:: Int = 0

    # Validator
    # =========

    enable_validator::Bool = false
    is_valid::Bool = false
    regex::Regex = r".*"
    use_regex::Bool = false

    # Store an element of the type that will be parsed by the validator. This is
    # necessary to avoid type instability.
    parsed_data::P
end

################################################################################
#                                     API
################################################################################

function accept_focus(widget::WidgetInputField)
    # When accepting focus we must update the cursor position so that it can be
    # positioned in the position it was when the focus was released.
    _update_cursor(widget)

    request_update(widget)
    return true
end

function create_widget(::Val{:input_field},
                       parent::WidgetParent,
                       opc::ObjectPositioningConfiguration;
                       border::Bool = false,
                       color_valid::Int = 0,
                       color_invalid::Int = 0,
                       max_data_size::Int = 0,
                       validator = nothing,
                       parsed_data_sample = nothing)

    # Check if all positioning is defined and, if not, try to help by
    # automatically defining the height and/or width.
    _process_horizontal_info!(opc)
    _process_vertical_info!(opc)

    if opc.vertical == :unknown
        opc.height = !border ? 1 : 3
    end

    if opc.horizontal == :unknown
        opc.width = 30
    end

    # Validator.
    enable_validator = (validator != nothing)

    use_regex = false
    regex = r".*"

    if enable_validator
        # Check if the user wants a `Regex`. In this case, the parsed data will
        # be a string.
        if typeof(validator) <: Regex
            parsed_data = ""
            regex = validator
            use_regex = true

        # If the user passed a `DataType` derived from `Number`, then we can
        # guess the parsed data type.
        elseif typeof(validator) <: DataType && (validator <: Number)
            parsed_data = validator(0)

        # Otherwise, we must use the type of parsed data from the field
        # `parsed_data_sample` that must be provided. This is required to avoid
        # type instability when getting the data from the field.
        else
            parsed_data = parsed_data_sample
        end
    else
        parsed_data = ""
    end

    # Create the widget.
    widget = WidgetInputField(parent           = parent,
                              opc              = opc,
                              border           = border,
                              color_valid      = color_valid,
                              color_invalid    = color_invalid,
                              enable_validator = enable_validator,
                              max_data_size    = max_data_size,
                              parsed_data      = parsed_data,
                              regex            = regex,
                              use_regex        = use_regex)

    # Initialize the internal variables of the widget.
    init_widget!(widget)

    # Usable size.
    widget.size = border ? widget.width - 2 : widget.width

    # Add the new widget to the parent widget list.
    add_widget(parent, widget)

    @log info "create_widget" """
    A input field was created in $(obj_desc(parent)).
        Size        = ($(widget.height), $(widget.width))
        Coordinate  = ($(widget.top), $(widget.left))
        Positioning = ($(widget.opc.vertical),$(widget.opc.horizontal))
        Border      = $border
        Max. size   = $max_data_size
        Validator?  = $enable_validator
        Reference   = $(obj_to_ptr(widget))"""

    # Return the created widget.
    return widget
end

function process_focus(widget::WidgetInputField, k::Keystroke)
    @unpack border = widget

    @log verbose "process_focus" "$(obj_desc(widget)): Key pressed on focused input field."
    ret = @emit_signal widget key_pressed k

    if isnothing(ret)
        # Handle the input.
        if _handle_input(widget, k)
            # Update the cursor position.
            _update_cursor(widget)

            # Validate the input.
            _validator(widget)

            return true
        else
            return false
        end
    else
        return ret
    end
end

function redraw(widget::WidgetInputField)
    @unpack border, buffer, color_invalid, color_valid, curx, cury, data,
            is_valid, size, view = widget

    wclear(buffer)

    # Apply the color depending of the status of the field.
    color = (isempty(data) || is_valid) ? color_valid : color_invalid

    # Convert the data to string.
    if isempty(data)
        str = ""
    else
        aux = clamp(view + size - 1, 1, length(data))
        str = String(@view data[view:aux])
    end

    # Check if a border must be drawn.
    if border
        wborder(buffer)
        y₀ = x₀ = 1
    else
        y₀ = x₀ = 0
    end

    wattron(buffer, color)
    # First, print spaces to apply the styling.
    mvwprintw(buffer, y₀, x₀, " "^size)
    mvwprintw(buffer, y₀, x₀, str)
    wattroff(buffer, color)

    return nothing
end

function release_focus(widget::WidgetInputField)
    request_update(widget)
    return true
end

require_cursor(widget::WidgetInputField) = true

################################################################################
#                           Custom widget functions
################################################################################

"""
    clear_data!(widget::WidgetInputField)

Clear the data in the input field `widget`.

"""
function clear_data!(widget::WidgetInputField)
    empty!(widget.data)

    widget.cury  = 1
    widget.curx  = 1
    widget.vcury = 1
    widget.vcurx = 1
    widget.view  = 1

    request_update(widget)

    return nothing
end

"""
    get_data(widget::WidgetInputField)

Get the data of `widget`. If a validator of type `DataType` is provided, then it
will return the parsed data. Otherwise, it will return a string.

"""
function get_data(widget::WidgetInputField{P}) where P<:String
    # TODO: The data is parsed when `tryparse` is called. Can we avoid this
    # double call?
    if widget.is_valid
        return String(widget.data)
    else
        return nothing
    end
end

function get_data(widget::WidgetInputField{P}) where P
    # TODO: The data is parsed when `tryparse` is called. Can we avoid this
    # double call?
    if widget.is_valid
        return tryparse(P, String(widget.data))
    else
        return nothing
    end
end

################################################################################
#                              Private functions
################################################################################

function _handle_input(widget::WidgetInputField, k::Keystroke)
    @unpack  data, max_data_size, view, curx, cury, size, vcury, vcurx = widget

    # We do not support multiple lines yet.
    vcury  = 1
    cury   = 1

    # Number of spaces the virtual cursor must move.
    Δx = 0

    # Flag to inform if the widget must be updated.
    update = false

    # Release focus.
    if k.ktype == :tab
        # If validation is required, then handle focus only if the input is
        # valid of empty
        return !isempty(data) && (widget.enable_validator && !widget.is_valid)
    # Move cursor to the left.
    elseif k.ktype == :left
        Δx = -1
    # Move cursor to the right.
    elseif k.ktype == :right
        Δx = +1
    # Go to the beginning of the data.
    elseif k.ktype == :home
        Δx = -(vcurx-1)
    # Go to the end of the data.
    elseif k.ktype == :end
        Δx = length(data)-vcurx+1
    # Delete the previous character.
    elseif k.ktype == :backspace
        vcurx > 1 && deleteat!(data, vcurx-1)
        Δx = -1
        update = true
    # Delete the next character.
    elseif k.ktype == :delete
        vcurx ≤ length(data) && deleteat!(data, vcurx)
        update = true
    # Insert the character in the position of the virtual cursor.
    elseif k.ktype ∈ [:char, :utf8]
        if (max_data_size ≤ 0) || (length(data) < max_data_size)
            if isempty(data)
                push!(data, k.value[1])
            else
                pos = clamp(vcurx, 1, length(data)+1)
                insert!(data, pos, k.value[1])
            end
            Δx = +1
            update = true
        end
    # Unsupported key -- we do not pass the focus.
    else
        return true
    end

    # Limit for the cursors in the X-axis.
    cxlimit = max_data_size > 0 ? min(max_data_size, length(data)+1) :
                                  length(data) + 1

    # Update the position of the virtual cursor.
    vcurx = clamp(vcurx + Δx, 1, cxlimit)

    # Check if we must change the view of the field.
    if Δx < 0
        # If the cursor is at the right edge and it was commanded to move it to
        # the left, then just move the view.
        if (curx == size) && (view > 1)
            view += Δx

            # If the view reached the most left position, then we must move the
            # cursor.
            curx += min(0, view-1)

            update = true
        elseif curx > 1
            curx += Δx
        end
    elseif Δx > 0
        curx += Δx

        # If the cursor is at the right edge, then just move the view.
        if curx > size
            curx = size
            view += Δx
            update = true
        end
    end

    # The cursor position must not pass the data.
    curx = clamp(curx, 1, cxlimit)

    # Make sure that view is in the acceptable interval.
    #
    # If the field is completely filled, than we would not allow an additional
    # space for the cursor at the position a character would be added.
    max_view = length(data) - size + 2
    length(data) == max_data_size && (max_view -= 1)

    view = clamp(view, 1, max(1, max_view))

    # Request update if necessary.
    update && request_update(widget)

    # Repack values that were modified.
    @pack! widget = cury, curx, vcury, vcurx, view

    return true
end

function _update_cursor(widget::WidgetInputField)
    # Move the physical cursor to the correct position considering the border if
    # present.
    #
    # NOTE: The initial position here starts at 1, but in NCurses it starts in
    # 0.
    py = widget.border ? widget.cury : widget.cury-1
    px = widget.border ? widget.curx : widget.curx-1
    wmove(widget.buffer, py, px)

    return nothing
end

function _validator(widget::WidgetInputField)
    @unpack data, enable_validator, regex, parsed_data = widget

    if enable_validator
        data_str = String(data)

        if widget.use_regex
            widget.is_valid = validate_str(data_str, regex)
        else
            widget.is_valid = validate_str(data_str, parsed_data)
        end
    else
        widget.is_valid = true
    end

    return nothing
end
