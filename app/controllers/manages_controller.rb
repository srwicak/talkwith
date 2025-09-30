class ManagesController < ApplicationController
  before_action :authenticate_admin
  before_action :find_booking, only: [:approve, :reject]
  
  def index
    @pending_bookings = Booking.where(is_approved: false).order(:start_time)
    @approved_bookings = Booking.where(is_approved: true).order(:start_time)
  end
  
  def sync_from_google
    SyncFromGoogleCalendarJob.perform_later
    flash[:notice] = "Syncing events from Google Calendar..."
    redirect_to manage_appointments_path
  end
  
  def sync_to_google
    # Sync all approved bookings that haven't been synced yet
    pending_bookings = Booking.where(is_approved: true, google_calendar_event_id: nil)
    
    if pending_bookings.any?
      pending_bookings.each do |booking|
        Rails.logger.info "Manually syncing booking #{booking.id} to Google Calendar"
        SyncGoogleCalendarJob.perform_later(booking)
      end
      flash[:notice] = "Syncing #{pending_bookings.count} appointments to Google Calendar..."
    else
      flash[:alert] = "No pending appointments to sync to Google Calendar."
    end
    
    redirect_to manage_appointments_path
  end
  
  def approve
    if @booking.is_approved?
      flash[:alert] = "Appointment is already approved."
    elsif @booking.update(is_approved: true)
      flash[:notice] = "Appointment approved successfully! It will be synced to Google Calendar automatically."
    else
      flash[:alert] = "Failed to approve appointment: #{@booking.errors.full_messages.join(', ')}"
    end
    
    redirect_to manage_appointments_path
  end
  
  def reject
    google_event_id = @booking.google_calendar_event_id
    appointment_subject = @booking.subject
    appointment_email = @booking.email
    
    # Store appointment data as a hash (not ActiveRecord object) before destroying
    appointment_data = {
      name: @booking.name,
      email: @booking.email,
      subject: @booking.subject,
      description: @booking.description,
      start_time: @booking.start_time,
      end_time: @booking.end_time,
      timezone_offset: @booking.timezone_offset || "Asia/Jakarta"
    }
    
    if @booking.destroy
      # Send cancellation email with hash data instead of ActiveRecord object
      AppointmentMailer.cancelled_appointment_with_data(appointment_data, 'admin').deliver_later
      
      if google_event_id.present?
        flash[:notice] = "Appointment '#{appointment_subject}' has been rejected and removed from both database and Google Calendar. Cancellation email sent to #{appointment_email}."
      else
        flash[:notice] = "Appointment '#{appointment_subject}' has been rejected and removed. Cancellation email sent to #{appointment_email}."
      end
    else
      flash[:alert] = "Failed to reject appointment: #{@booking.errors.full_messages.join(', ')}"
    end
    
    redirect_to manage_appointments_path
  end

  private

  def authenticate_admin
    # Check if user is signed in and is admin
    unless Current.user&.email_address == "me@sandyrw.com"
      flash[:alert] = "Access denied. Admin access required."
      redirect_to new_user_session_path
    end
  end

  def find_booking
    @booking = Booking.find(params[:id])
  end
end
