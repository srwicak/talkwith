module Manages
  class UdiConfigurationsController < ApplicationController
    # Allow unauthenticated access for development testing
    allow_unauthenticated_access

    def index
      @configurations = UdiConfiguration.order(:day_of_week)
    end

    def new
      @configuration = UdiConfiguration.new
    end

    def create
      @configuration = UdiConfiguration.new(configuration_params)

      if @configuration.save
        redirect_to manages_udi_configurations_path, notice: "✅ Konfigurasi hari berhasil ditambahkan!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @configuration = UdiConfiguration.find(params[:id])
    end

    def update
      @configuration = UdiConfiguration.find(params[:id])

      if @configuration.update(configuration_params)
        redirect_to manages_udi_configurations_path, notice: "✅ Konfigurasi berhasil diupdate!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @configuration = UdiConfiguration.find(params[:id])
      @configuration.destroy

      redirect_to manages_udi_configurations_path, notice: "🗑️ Konfigurasi berhasil dihapus!"
    end

    def toggle_enabled
      @configuration = UdiConfiguration.find(params[:id])
      @configuration.update(enabled: !@configuration.enabled)

      status = @configuration.enabled ? "diaktifkan" : "dinonaktifkan"
      redirect_to manages_udi_configurations_path, notice: "✅ Konfigurasi #{status}!"
    end

    private

    def configuration_params
      params.require(:udi_configuration).permit(:day_of_week, :start_time, :end_time, :slot_duration, :buffer_time, :enabled)
    end
  end
end
