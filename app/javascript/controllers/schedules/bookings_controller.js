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
            <h3 class="font-bold text-green-600 dark:text-green-400 mb-2">Approved Events</h3>
            <div class="space-y-3">
              ${approvedEvents
                .map(
                  (event) => `
                <div class="p-3 bg-green-50 dark:bg-green-900 rounded-lg shadow">
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
            : `<p class="text-gray-500 dark:text-gray-400 mb-4"><i>No approved events for this day.</i></p>`
        }

        ${
          nonApprovedEvents.length > 0
            ? `
          <div class="pending-events border border-yellow-500 rounded-lg p-4 bg-white dark:bg-gray-800">
            <h3 class="font-bold text-yellow-600 dark:text-yellow-400 mb-2">Pending/Not Approved Events</h3>
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

    // Check if this is a UDI x ITB booking
    const isUDIxITBBooking = subject.includes("[UDIxITB]");

    // Date validation
    if (isUDIxITBBooking) {
      // Only allow October 2025
      if (dateInput.getFullYear() !== 2025 || dateInput.getMonth() !== 9) { // Month is 0-indexed, October = 9
        this.errorDateTarget.textContent = `Date must be in October 2025 for UDI x ITB bookings.`;
        isValid = false;
      }
      
      // For UDI x ITB bookings: only allow dates within current Sunday week
      const currentSundayWeek = this.getCurrentSundayWeekRange();
      if (dateInput < currentSundayWeek.start || dateInput > currentSundayWeek.end) {
        this.errorDateTarget.textContent = `Date must be within the current Sunday week for UDI x ITB bookings.`;
        isValid = false;
      }
      
      // Only allow Thursday (4) and Friday (5)
      const dayOfWeek = dateInput.getDay();
      if (![4, 5].includes(dayOfWeek)) {
        this.errorDateTarget.textContent = `Date must be on Thursday or Friday for UDI x ITB bookings.`;
        isValid = false;
      }
      
      if (isValid) {
        this.errorDateTarget.textContent = "";
      }
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

    // Duration validation
    if (duration <= 0) {
      this.errorTimeTarget.textContent = `End time must be after start time.`;
      isValid = false;
    } else if (isUDIxITBBooking) {
      // Special validation for UDI x ITB bookings (20-30 minutes)
      if (duration < 20) {
        this.errorTimeTarget.textContent = `Duration must be at least 20 minutes for UDI x ITB bookings.`;
        isValid = false;
      } else if (duration > 30) {
        this.errorTimeTarget.textContent = `Duration must be at most 30 minutes for UDI x ITB bookings.`;
        isValid = false;
      } else {
        this.errorTimeTarget.textContent = "";
      }
    } else {
      // Normal validation for regular bookings (15-120 minutes)
      if (duration < 15) {
        this.errorTimeTarget.textContent = `Duration must be at least 15 minutes.`;
        isValid = false;
      } else if (duration > 120) {
        this.errorTimeTarget.textContent = `Duration must be at most 120 minutes.`;
        isValid = false;
      } else {
        this.errorTimeTarget.textContent = "";
      }
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
    
    if (data.errors && data.errors.length > 0) {
      data.errors.forEach(error => {
        // UDI x ITB specific errors
        if (error.includes("October 2025 for UDI x ITB")) {
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
    
    // Simple HTML - just list the errors
    let errorHtml = `
      <p class="text-sm font-medium text-gray-800 mb-3">Your booking failed for the following reasons:</p>
    `;
    
    friendlyErrors.forEach(error => {
      errorHtml += `
        <div class="mb-2 p-2 bg-red-50 rounded border-l-4 border-red-400">
          <p class="text-sm text-red-700">${error}</p>
        </div>
      `;
    });
    
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
}
