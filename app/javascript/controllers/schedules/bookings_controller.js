import { Controller } from "@hotwired/stimulus";

console.log("Bookings controller file loaded"); // Debug log

// Connects to data-controller="schedules--bookings"
export default class extends Controller {
  static targets = [
    "calendar",
    "dateInput",
    "eventList",
    "monthYear",
    "scheduleModal",
    "userTimezone",
    "successModal",
    "conflictModal",
    "failedModal",
    "field",
    "error",
    "errorDate",
    "startTime",
    "endTime",
    "errorTime",
    "subject",
    "errorDetails"
  ];
  async connect() {
    console.log('Bookings controller connected'); // Debug log
    console.log('Available targets:', Object.keys(this).filter(key => key.endsWith('Target'))); // Debug log
    
    this.today = new Date();
    this.currentDate = new Date();
    this.currentMonth = this.today.getMonth();
    this.currentYear = this.today.getFullYear();
    this.tomorrowDate = new Date(this.today.getTime() + 24 * 60 * 60 * 1000);
    this.maxDate = new Date(this.tomorrowDate);
    this.maxDate.setMonth(this.maxDate.getMonth() + 2);

    this.formattedTomorrowDate = `${
      this.tomorrowDate.getMonth() + 1
    }/${this.tomorrowDate.getDate()}/${this.tomorrowDate.getFullYear()}`;

    this.formattedMaxDate = `${
      this.maxDate.getMonth() + 1
    }/${
      this.maxDate.getDate() - 1
    }/${this.maxDate.getFullYear()}`;

    this.userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    this.todayLocalDate = `${this.today.getFullYear()}-${(
      this.today.getMonth() + 1
    )
      .toString()
      .padStart(2, "0")}-${this.today.getDate().toString().padStart(2, "0")}`;

    this.events = [];

    this.dateInputTarget.setAttribute(
      "datepicker-min-date",
      this.formattedTomorrowDate
    );
    this.dateInputTarget.setAttribute(
      "datepicker-max-date",
      this.formattedMaxDate
    );
    await this.loadEvents();
    this.displayEvents(this.todayLocalDate);
    this.userTimezoneTarget.textContent = `${this.userTimezone}`;
    
    console.log('Bookings controller fully initialized'); // Debug log
  }

  // TODO: multi timezone fetching data
  async loadEvents() {
    const url = `/bookings?month=${this.currentMonth + 1}&year=${
      this.currentYear
    }`;
    const response = await fetch(url);
    if (response.ok) {
      this.events = await response.json();
      this.renderCalendar();
    } else {
      this.events = [];
      this.renderCalendar();
    }
    return Promise.resolve();
  }

  renderCalendar() {
    const firstDay = new Date(this.currentYear, this.currentMonth, 1);
    const lastDay = new Date(this.currentYear, this.currentMonth + 1, 0);

    const firstDayIndex = firstDay.getDay();
    const daysInMonth = lastDay.getDate();

    this.calendarTarget.innerHTML = "";
    this.eventListTarget.innerHTML = "";
    this.monthYearTarget.textContent = firstDay.toLocaleString("default", {
      month: "long",
      year: "numeric",
    });

    // Add empty slots for days of the previous month
    for (let day = 0; day < firstDayIndex; day++) {
      this.calendarTarget.innerHTML += `<div class="h-16"></div>`;
    }

    // Add days of the current month
    for (let day = 1; day <= daysInMonth; day++) {
      const dateString = `${this.currentYear}-${(this.currentMonth + 1)
        .toString()
        .padStart(2, "0")}-${day.toString().padStart(2, "0")}`;

      const eventsForDay = this.events.filter((e) => e.date === dateString);

      this.calendarTarget.innerHTML += `
        <div class="h-16 border rounded flex flex-col items-center justify-center hover:bg-blue-100 dark:bg-gray-600 dark:text-white dark:hover:bg-blue-900 cursor-pointer ${
          eventsForDay.length > 0 ? "bg-blue-200 dark:bg-blue-800" : ""
        } ${
        dateString === this.todayLocalDate ? "border-4 border-blue-500" : ""
      }"
        data-date="${dateString}">
          <span class="font-semibold">${day}</span>
          ${
            eventsForDay.length > 0
              ? `<span class="text-xs text-red-500">(${
                  eventsForDay.length
                } event${eventsForDay.length > 1 ? "s" : ""})</span>`
              : ""
          }
        </div>
      `;
    }

    this.calendarTarget.addEventListener("click", (event) => {
      const dateDiv = event.target.closest("[data-date]");
      if (dateDiv) {
        this.calendarTarget.querySelectorAll("[data-date]").forEach((el) => {
          el.classList.remove("ring", "ring-green-500", "dark:ring-green-400");
        });
        dateDiv.classList.add("ring", "ring-green-500", "dark:ring-green-400");
        this.displayEvents(dateDiv.dataset.date);
      }
    });
  }

  handleClickDate(date) {
    this.displayEvents(date);
  }

  displayEvents(date) {
    this.eventListTarget.innerHTML = "";
    const eventsForDay = this.events.filter((e) => e.date === date);
    if (eventsForDay.length > 0) {

      // Split events into approved and non-approved
      const approvedEvents = eventsForDay.filter((e) => e.approved == true);
      const nonApprovedEvents = eventsForDay.filter((e) => e.approved == false);

      this.eventListTarget.innerHTML = `
        ${
          approvedEvents.length > 0
            ? `
          <div class="approved-events border border-green-500 rounded-lg p-4 mb-4 bg-white dark:bg-gray-800">
            <h3 class="font-bold text-green-600 dark:text-green-400 mb-2">📅 Scheduled Sessions</h3>
            ${this.generateBufferInfo(approvedEvents)}
            <div class="space-y-3">
              ${approvedEvents
                .map(
                  (event) => {
                    const isUDI = event.subject.includes('[UDIxITB]');
                    const startTime = new Date(event.start_time);
                    const endTime = new Date(event.end_time);
                    const bufferMinutes = isUDI ? this.calculateBufferForEvent(approvedEvents, startTime) : 0;
                    const effectiveEndTime = new Date(endTime.getTime() + bufferMinutes * 60000);
                    
                    return `
                <div class="p-3 ${isUDI ? 'bg-purple-50 border border-purple-200' : 'bg-green-50'} dark:bg-green-900 rounded-lg shadow">
                  <span class="block font-semibold text-gray-800 dark:text-gray-200">${
                    event.subject
                  }
                    ${isUDI ? '<span class="text-xs bg-purple-100 text-purple-800 px-2 py-1 rounded ml-2">UDI x ITB</span>' : ''}
                  </span>
                  <span class="block text-xs text-gray-500 dark:text-gray-400">
                    Session: ${startTime.toLocaleTimeString()} - ${endTime.toLocaleTimeString()}
                    ${isUDI ? `<br>Buffer: +${bufferMinutes} min (until ${effectiveEndTime.toLocaleTimeString()})` : ''}
                  </span>
                  ${isUDI ? `<span class="block text-xs text-green-600 mt-1">✅ Next available: ${effectiveEndTime.toLocaleTimeString()}</span>` : ''}
                </div>
              `;
                  }
                )
                .join("")}
            </div>
          </div>
        `
            : `<p class="text-gray-500 dark:text-gray-400 mb-4"><i>No approved events for this day.</i></p>`
        }

        ${
          nonApprovedEvents.length > 0
            ? `
          <div class="pending-events border border-yellow-500 rounded-lg p-4 bg-white dark:bg-gray-800">
            <h3 class="font-bold text-yellow-600 dark:text-yellow-400 mb-2">⏳ Pending Approval</h3>
            <div class="space-y-3">
              ${nonApprovedEvents
                .map(
                  (event) => `
                <div class="p-3 bg-yellow-50 dark:bg-yellow-900 rounded-lg shadow">
                  <span class="block font-semibold text-gray-800 dark:text-gray-200">${
                    event.subject
                  }</span>
                  <span class="block text-xs text-gray-500 dark:text-gray-400">${new Date(
                    event.start_time
                  ).toLocaleTimeString()} - ${new Date(
                    event.end_time
                  ).toLocaleTimeString()}</span>
                </div>
              `
                )
                .join("")}
            </div>
          </div>
        `
            : `<p class="text-gray-500 dark:text-gray-400"><i>No pending or not approved events for this day.</i></p>`
        }
      `;
    } else {
      const noEventMessage =
        date === this.todayLocalDate
          ? "No events/schedules for today."
          : "No events/schedules for this day.";
      this.eventListTarget.innerHTML = `<i>${noEventMessage}</i>`;
    }
  }

  now() {
    this.currentMonth = this.today.getMonth();
    this.currentYear = this.today.getFullYear();
    this.loadEvents().then(() => {
      this.displayEvents(this.todayLocalDate);
    });
  }

  previousMonth() {
    this.currentMonth--;
    if (this.currentMonth < 0) {
      this.currentMonth = 11;
      this.currentYear--;
    }
    this.loadEvents().then(() => {
      this.eventListTarget.innerHTML += `<i>Please pick a date</i>`;
    });
  }

  nextMonth() {
    this.currentMonth++;
    if (this.currentMonth > 11) {
      this.currentMonth = 0;
      this.currentYear++;
    }
    this.loadEvents().then(() => {
      this.eventListTarget.innerHTML += `<i>Please pick a date</i>`;
    });
  }

  showFormModal() {
    this.scheduleModalTarget.setAttribute("aria-hidden", "false");
    this.scheduleModalTarget.classList.remove(
      "opacity-0",
      "pointer-events-none"
    );
    this.scheduleModalTarget
      .querySelectorAll("input, select, textarea, button")
      .forEach((el) => {
        el.disabled = false;
      });
    this.scheduleModalTarget.querySelector("form").reset();
  }

  hideFormModal() {
    this.scheduleModalTarget.setAttribute("aria-hidden", "true");
    this.scheduleModalTarget.classList.add("opacity-0", "pointer-events-none");
    this.scheduleModalTarget
      .querySelectorAll("input, select, textarea, button")
      .forEach((el) => {
        el.disabled = true;
      });
    this.scheduleModalTarget.querySelector("form").reset();
  }

  submitAppointment(event) {
    event.preventDefault();

    if (!this.validateForm()) {
      return;
    }

    const form = event.target.closest("form");
    const formData = new FormData(form);

    fetch(form.action, {
      method: form.method,
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body: formData,
    })
      .then((response) => {
        return response.json().then((data) => ({
          status: response.status,
          data,
        }));
      })
      .then(({ status, data }) => {
        if (status === 201) {
          console.log(data);
          this.hideFormModal();
          this.successModalTarget.classList.remove("hidden");
        } else if (status === 409) {
          this.conflictModalTarget.classList.remove("hidden");
        } else {
          this.showErrorModal(data);
        }
      })
      .catch((error) => {
        this.showErrorModal({ errors: ["Network error occurred. Please try again."] });
      });
  }

  validateForm() {
    let isValid = true;
    let dateInput = new Date(this.dateInputTarget.value);
    let startTime = this.startTimeTarget.value;
    let endTime = this.endTimeTarget.value;
    let subject = this.subjectTarget.value;

    if (!dateInput || !startTime || !endTime) {
      isValid = false;
    }

    // Block manual UDI x ITB booking - they must use special booking page
    if (subject.includes("[UDIxITB]") || subject.toLowerCase().includes("udi") || subject.toLowerCase().includes("itb")) {
      // Clear previous error messages
      this.errorDateTarget.textContent = "";
      this.errorTimeTarget.textContent = "";
      
      // Set specific error for UDI blocking
      const subjectErrorElement = this.fieldTargets.find(field => field.name === "booking[subject]")?.nextElementSibling;
      if (subjectErrorElement && subjectErrorElement.classList.contains('error-message')) {
        subjectErrorElement.textContent = "⚠️ UDI x ITB bookings must use the special booking link. Please contact admin for access.";
      }
      
      // Also show general error
      if (this.errorDetailsTarget) {
        this.errorDetailsTarget.innerHTML = `
          <div class="mb-3 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div class="flex items-center mb-2">
              <span class="text-blue-500 mr-2">ℹ️</span>
              <h4 class="font-medium text-blue-800">UDI x ITB Special Booking Required</h4>
            </div>
            <p class="text-sm text-blue-700 mb-3">
              UDI x ITB coaching sessions require special scheduling through a dedicated booking page.
            </p>
            <div class="text-xs text-blue-600">
              <p>• Contact admin for the special booking link</p>
              <p>• Use pre-configured time slots</p>
              <p>• Automatic session approval</p>
            </div>
          </div>
        `;
      }
      
      return false;
    }

    // Check if this is a UDI x ITB booking (this shouldn't happen anymore due to above check)
    const isUDIxITBBooking = subject.includes("[UDIxITB]");

    // Date validation
    if (isUDIxITBBooking) {
      // This block should not be reached anymore, but keeping for safety
      this.errorDateTarget.textContent = "UDI x ITB bookings must be made through the special booking page.";
      isValid = false;
    } else {
      // Normal validation for regular bookings
      if (dateInput < new Date(this.formattedTomorrowDate)) {
        this.errorDateTarget.textContent = `Date must be in the future.`;
        isValid = false;
      } else if (dateInput > new Date(this.formattedMaxDate)) {
        this.errorDateTarget.textContent = `Date must be before ${this.formattedMaxDate}.`;
        isValid = false;
      } else {
        this.errorDateTarget.textContent = "";
      }
    }

    let start = new Date(`1970-01-01T${startTime}`);
    let end = new Date(`1970-01-01T${endTime}`);

    let duration = (end - start) / 60000;

    // Duration validation - only for regular bookings since UDI is blocked above
    if (duration <= 0) {
      this.errorTimeTarget.textContent = `End time must be after start time.`;
      isValid = false;
    } else if (duration < 15) {
      this.errorTimeTarget.textContent = `Duration must be at least 15 minutes.`;
      isValid = false;
    } else if (duration > 120) {
      this.errorTimeTarget.textContent = `Duration must be at most 120 minutes.`;
      isValid = false;
    } else {
      this.errorTimeTarget.textContent = "";
    }

    this.fieldTargets.forEach((field, index) => {
      const error = this.errorTargets[index];
      error.textContent = "";

      if (field.required && !field.value.trim()) {
        error.textContent = `This field is required.`;
        isValid = false;
      }

      if (field.name === "booking[name]" && field.value.length < 3) {
        error.textContent = `Name must be at least 3 characters long.`;
        isValid = false;
      }

      if (field.name === "booking[email]" && field.value) {
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailPattern.test(field.value)) {
          error.textContent = `Email must be a valid email address.`;
          isValid = false;
        }
      }

      if (field.name === "booking[subject]" && field.value.length < 3) {
        error.textContent = `Subject must be at least 3 characters long.`;
        isValid = false;
      }

      if (field.name === "booking[description]" && field.value.length < 20) {
        error.textContent = `Description must be at least 20 characters long.`;
        isValid = false;
      }
      
    });
    return isValid;
  }

  handleSuccess(data) {
    // Modal Success
    const modal = document.getElementById("success-modal");
    const closeModalButton = document.getElementById("close-modal");

    modal.classList.remove("hidden");

    closeModalButton.addEventListener("click", () => {
      modal.classList.add("hidden");
    });
  }

  handleError(error) {
    // Modal Failed
    const modal = document.getElementById("failed-modal");
    const closeModalButton = document.getElementById("close-modal");

    modal.classList.remove("hidden");

    closeModalButton.addEventListener("click", () => {
      modal.classList.add("hidden");
    });
  }

  hideSuccessModal() {
    window.location.reload();
  }

  hideConflictModal() {
    this.conflictModalTarget.classList.add("hidden");
  }

  hideFailedModal() {
    this.failedModalTarget.classList.add("hidden");
  }

  // Show error modal with specific error messages
  showErrorModal(data) {
    console.log('Error data received:', data);
    
    if (!this.errorDetailsTarget) {
      console.error('Error details target not found');
      return;
    }
    
    // Convert error messages to specific user-friendly text
    let friendlyErrors = [];
    let suggestedTimes = [];
    
    if (data.errors && data.errors.length > 0) {
      data.errors.forEach(error => {
        // Enhanced UDI x ITB buffer conflict handling
        if (error.includes("includes") && error.includes("minute buffer")) {
          // Extract the next available time from error message
          const timeMatch = error.match(/Next available time: (\d{2}:\d{2})/);
          const nextTime = timeMatch ? timeMatch[1] : null;
          
          friendlyErrors.push("⏰ UDI x ITB session buffer conflict detected");
          
          if (nextTime) {
            suggestedTimes.push(`✅ ${nextTime}-${this.addMinutes(nextTime, 30)} (Recommended)`);
            suggestedTimes.push(`✅ ${this.addMinutes(nextTime, 35)}-${this.addMinutes(nextTime, 65)}`);
            suggestedTimes.push(`✅ ${this.addMinutes(nextTime, 70)}-${this.addMinutes(nextTime, 100)}`);
          }
        }
        // UDI x ITB specific errors
        else if (error.includes("October 2025 for UDI x ITB")) {
          friendlyErrors.push("❌ UDI x ITB bookings are only available in October 2025");
        } else if (error.includes("current Sunday week for UDI x ITB")) {
          friendlyErrors.push("❌ You cannot schedule UDI x ITB meetings outside of the current week");
        } else if (error.includes("Thursday or Friday for UDI x ITB")) {
          friendlyErrors.push("❌ UDI x ITB meetings can only be scheduled on Thursday or Friday");
        } else if (error.includes("20 minutes for UDI x ITB")) {
          friendlyErrors.push("❌ Meeting duration must be between 20-30 minutes for UDI x ITB bookings");
        } else if (error.includes("30 minutes for UDI x ITB")) {
          friendlyErrors.push("❌ Meeting duration must be between 20-30 minutes for UDI x ITB bookings");
        }
        // Regular booking errors
        else if (error.includes("from tommorow up to 2 months ahead")) {
          friendlyErrors.push("❌ Appointments can only be scheduled from tomorrow up to 2 months ahead");
        } else if (error.includes("in the past")) {
          friendlyErrors.push("❌ You cannot schedule appointments in the past");
        } else if (error.includes("at least 15 minutes")) {
          friendlyErrors.push("❌ Regular appointments must be at least 15 minutes long");
        } else if (error.includes("no more than 2 hours") || error.includes("cannot be more than 2 hours")) {
          friendlyErrors.push("❌ Regular appointments cannot be longer than 2 hours");
        } else if (error.includes("after start time")) {
          friendlyErrors.push("❌ End time must be after start time");
        } else if (error.includes("valid email") || error.includes("Email is invalid")) {
          friendlyErrors.push("❌ Please enter a valid email address");
        } else if (error.includes("Name is too short") || error.includes("Name must be at least 3 characters")) {
          friendlyErrors.push("❌ Name must be at least 3 characters long");
        } else if (error.includes("Subject is too short") || error.includes("Subject must be at least 3 characters")) {
          friendlyErrors.push("❌ Subject must be at least 3 characters long");
        } else if (error.includes("Description must be at least 20 characters")) {
          friendlyErrors.push("❌ Description must be at least 20 characters long");
        } else if (error.includes("can't be blank")) {
          friendlyErrors.push("❌ All fields are required");
        } else if (error.includes("overlaps with") || error.includes("Booking overlaps")) {
          friendlyErrors.push("❌ This time slot conflicts with another appointment");
        } else {
          // Fallback: show original error with ❌
          friendlyErrors.push("❌ " + error);
        }
      });
    } else {
      friendlyErrors.push("❌ Something went wrong. Please check your input and try again.");
    }
    
    // Generate enhanced error HTML with suggestions
    let errorHtml = `
      <p class="text-sm font-medium text-gray-800 mb-3">Your booking failed for the following reasons:</p>
    `;
    
    friendlyErrors.forEach(error => {
      if (error.includes("buffer conflict")) {
        errorHtml += `
          <div class="mb-3 p-3 bg-purple-50 rounded border-l-4 border-purple-400">
            <p class="text-sm font-medium text-purple-800 mb-2">UDI x ITB Smart Scheduling</p>
            <p class="text-sm text-purple-700">${error}</p>
          </div>
        `;
      } else {
        errorHtml += `
          <div class="mb-2 p-2 bg-red-50 rounded border-l-4 border-red-400">
            <p class="text-sm text-red-700">${error}</p>
          </div>
        `;
      }
    });
    
    if (suggestedTimes.length > 0) {
      errorHtml += `
        <div class="mb-3 p-3 bg-blue-50 rounded border-l-4 border-blue-400">
          <p class="text-sm font-bold text-blue-800 mb-2">💡 Available Time Slots:</p>
          <ul class="text-sm text-blue-700 space-y-1">
            ${suggestedTimes.map(time => `<li>${time}</li>`).join('')}
          </ul>
        </div>
      `;
    }
    
    // Set the HTML and show modal
    this.errorDetailsTarget.innerHTML = errorHtml;
    this.failedModalTarget.classList.remove('hidden');
    
    console.log('Error modal shown with:', friendlyErrors);
  }

  // Helper method to get current Sunday week range
  getCurrentSundayWeekRange() {
    const today = new Date();
    
    // Get current Sunday (start of week)
    const currentSunday = new Date(today);
    const daysSinceLastSunday = today.getDay(); // 0 = Sunday, 1 = Monday, etc.
    currentSunday.setDate(today.getDate() - daysSinceLastSunday);
    currentSunday.setHours(0, 0, 0, 0);
    
    // Get next Sunday (end of current week)
    const nextSunday = new Date(currentSunday);
    nextSunday.setDate(currentSunday.getDate() + 6); // Saturday is the last day of the week
    nextSunday.setHours(23, 59, 59, 999);
    
    return {
      start: currentSunday,
      end: nextSunday
    };
  }

  // Calculate buffer time for UDI x ITB events based on session count
  calculateBufferForEvent(allEvents, eventStartTime) {
    // Count UDI x ITB events on the same day
    const sameDay = allEvents.filter(e => {
      const eDate = new Date(e.start_time).toDateString();
      const targetDate = eventStartTime.toDateString();
      return eDate === targetDate && e.subject.includes('[UDIxITB]');
    }).length;
    
    // Return adaptive buffer based on session count
    if (sameDay <= 3) return 5;
    if (sameDay <= 6) return 4;
    if (sameDay <= 8) return 3;
    if (sameDay <= 10) return 2;
    return 1;
  }

  // Generate buffer info display for approved events
  generateBufferInfo(approvedEvents) {
    const udiEvents = approvedEvents.filter(e => e.subject.includes('[UDIxITB]'));
    if (udiEvents.length === 0) return '';
    
    const bufferTime = this.calculateBufferForEvent(approvedEvents, new Date(udiEvents[0].start_time));
    
    return `
      <div class="bg-purple-50 border border-purple-200 rounded-lg p-3 mb-4">
        <div class="flex items-center">
          <span class="text-purple-800 mr-2">⏰</span>
          <span class="text-sm text-purple-800">
            UDI x ITB sessions today: ${udiEvents.length} | Buffer time: ${bufferTime} minutes
          </span>
        </div>
        <div class="text-xs text-purple-600 mt-1">
          Buffer automatically adjusts based on daily session density for optimal scheduling
        </div>
      </div>
    `;
  }

  // Helper method to add minutes to time string
  addMinutes(timeStr, minutes) {
    const [hours, mins] = timeStr.split(':').map(Number);
    const totalMinutes = hours * 60 + mins + minutes;
    const newHours = Math.floor(totalMinutes / 60);
    const newMins = totalMinutes % 60;
    return `${newHours.toString().padStart(2, '0')}:${newMins.toString().padStart(2, '0')}`;
  }
}
