module Schedules
  class UdiBookingsController < ApplicationController
    # Allow unauthenticated access for UDI booking
    allow_unauthenticated_access
    
    def new
      @booking = Booking.new
      @available_dates = Booking.current_week_udi_dates
      @available_slots_by_date = {}
      
      @available_dates.each do |date|
        @available_slots_by_date[date] = Booking.get_grouped_slots_for_date(date)
      end
    end
    
    def create
      @booking = Booking.new(udi_booking_params)
      
      # Mark as coming from UDI route to bypass validation
      @booking.mark_from_udi_route!
      
      # Add UDI tag if not present
      unless @booking.subject.include?('[UDIxITB]')
        @booking.subject = "[UDIxITB] #{@booking.subject}"
      end
      
      # Validate and set time based on selected slot
      if validate_and_set_slot_time
        if @booking.save
          AppointmentMailer.new_appointment(@booking, appointment_url(@booking.slug)).deliver_later
          redirect_to appointment_path(@booking.slug), notice: "🎯 UDI x ITB session booked successfully!"
        else
          reload_form_data
          flash.now[:error] = "Please fix the errors below"
          render :new
        end
      else
        reload_form_data  
        flash.now[:error] = "Please select a valid time slot"
        render :new
      end
    end
    
    def available_slots
      date = Date.strptime(params[:date], "%Y-%m-%d") rescue nil
      
      if date
        grouped_slots = Booking.get_grouped_slots_for_date(date)
        render json: { 
          success: true,
          grouped_slots: grouped_slots,
          total_count: grouped_slots.values.sum { |session| session[:count] }
        }
      else
        render json: { success: false, grouped_slots: {}, total_count: 0 }
      end
    end
    
    private
    
    def udi_booking_params
      params.require(:booking).permit(:name, :email, :subject, :description, :timezone_offset)
    end
    
    def validate_and_set_slot_time
      selected_date = Date.strptime(params[:selected_date], "%Y-%m-%d") rescue nil
      selected_slot = params[:selected_slot]
      
      unless selected_date && selected_slot
        @booking.errors.add(:base, "Please select a date and time slot")
        return false
      end
      
      # Check if slot is still available
      available_slots = Booking.available_udi_slots_for_date(selected_date)
      slot_info = available_slots.find { |s| s[:start] == selected_slot }
      
      unless slot_info
        @booking.errors.add(:base, "Selected time slot is no longer available")
        return false
      end
      
      # Set the date and times
      timezone = ActiveSupport::TimeZone[@booking.timezone_offset || "Asia/Jakarta"]
      date_str = selected_date.strftime("%m/%d/%Y")
      
      @booking.date = date_str
      @booking.start_time = slot_info[:start]
      @booking.end_time = slot_info[:end]
      
      true
    end
    
    def reload_form_data
      @available_dates = Booking.current_week_udi_dates
      @available_slots_by_date = {}
      
      @available_dates.each do |date|
        @available_slots_by_date[date] = Booking.get_grouped_slots_for_date(date)
      end
    end
  end
end