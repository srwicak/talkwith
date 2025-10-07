module Manages
  class UdiSettingsController < ApplicationController
    # Allow unauthenticated access for development testing
    allow_unauthenticated_access
    
    def index
      @available_dates = Booking.current_week_udi_dates
      @all_slots_by_day = {}
      @disabled_slots = Booking.get_disabled_udi_slots
      
      # Get all slots for each available date
      @available_dates.each do |date|
        day_name = date.strftime('%A').downcase
        @all_slots_by_day[date] = Booking.get_slots_for_day(day_name)
      end
      
      # Get booking counts
      @booking_counts = get_booking_counts
      
      # Generate stats
      @stats = calculate_stats
    end
    
    def update_slots
      disabled_slots = {}
      
      # Process form data - convert enabled_slots to disabled_slots
      if params[:enabled_slots].present?
        @available_dates = Booking.current_week_udi_dates
        
        @available_dates.each do |date|
          date_key = date.strftime('%Y-%m-%d')
          day_name = date.strftime('%A').downcase
          all_slots_for_day = Booking.get_slots_for_day(day_name)
          enabled_slots_for_date = params[:enabled_slots][date_key] || []
          
          # Find slots that are NOT enabled (i.e., disabled)
          disabled_for_date = all_slots_for_day.map { |slot| slot[:start] } - enabled_slots_for_date
          disabled_slots[date_key] = disabled_for_date if disabled_for_date.any?
        end
      end
      
      # Save to cache
      Booking.set_disabled_udi_slots(disabled_slots)
      
      redirect_to manages_udi_settings_path, notice: "✅ Time slot settings updated successfully!"
    end
    
    def reset_week
      # Clear all disabled slots for current week
      Booking.set_disabled_udi_slots({})
      
      redirect_to manages_udi_settings_path, notice: "🔄 All slots have been enabled for this week"
    end
    
    private
    
    def get_booking_counts
      counts = {}
      
      @available_dates.each do |date|
        counts[date] = {}
        
        day_slots = @all_slots_by_day[date] || []
        day_slots.each do |slot|
          count = Booking.where(
            "DATE(start_time) = ? AND TIME(start_time) = ? AND subject LIKE ? AND is_approved = ?",
            date,
            Time.parse(slot[:start]),
            "%[UDIxITB]%",
            true
          ).count
          
          counts[date][slot[:start]] = count
        end
      end
      
      counts
    end
    
    def calculate_stats
      total_slots = 0
      total_available = 0
      total_booked = 0
      total_disabled = 0
      
      @available_dates.each do |date|
        date_key = date.strftime('%Y-%m-%d')
        day_slots = @all_slots_by_day[date] || []
        disabled_for_date = @disabled_slots[date_key] || []
        
        day_slots.each do |slot|
          total_slots += 1
          
          if disabled_for_date.include?(slot[:start])
            total_disabled += 1
          elsif (@booking_counts.dig(date, slot[:start]) || 0) > 0
            total_booked += 1
          else
            total_available += 1
          end
        end
      end
      
      {
        total_slots: total_slots,
        total_available: total_available,
        total_booked: total_booked,
        total_disabled: total_disabled
      }
    end
    
    def authenticate_user!
      # TODO: Implement your authentication logic here
      # For development, we'll allow access
      # In production, uncomment the line below:
      # redirect_to root_path, alert: "Access denied" unless current_user&.admin?
      
      Rails.logger.info "UDI Settings accessed - implement authentication as needed"
    end
  end
end