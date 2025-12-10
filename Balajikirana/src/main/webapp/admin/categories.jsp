<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<script src="https://cdn.tailwindcss.com"></script>

<!doctype html>
<html>
<head>
  <title>Add Category (image via file or URL)</title>
</head>
<body class="bg-gray-100 min-h-screen flex items-center justify-center p-6">

  <div class="bg-white rounded-xl shadow-lg w-full max-w-2xl p-6">
    <h2 class="text-2xl font-bold text-green-700 mb-4">Add Category</h2>

   <form method="post" action="<%=request.getContextPath()%>/AddCategoryServlet" enctype="multipart/form-data">
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">Category name</label>
        <input name="name" required
               class="w-full rounded-lg border px-4 py-2 focus:ring-2 focus:ring-green-300" placeholder="e.g. Snacks" />
      </div>

      <!-- Toggle: choose file or URL -->
      <div class="flex gap-2 items-center text-sm">
        <label class="inline-flex items-center gap-2">
          <input type="radio" name="imgMode" value="file" checked class="form-radio h-4 w-4" /> 
          <span>Upload file</span>
        </label>
        <label class="inline-flex items-center gap-2 ml-4">
          <input type="radio" name="imgMode" value="url" class="form-radio h-4 w-4" />
          <span>Use image URL</span>
        </label>
        <div class="ml-auto text-xs text-slate-500">You can drag & drop an image too.</div>
      </div>

      <!-- File upload / drag & drop area -->
      <div id="dropArea" class="relative rounded-lg border-2 border-dashed border-slate-200 p-4 text-center bg-slate-50">
        <input id="fileInput" type="file" name="image" accept="image/*" class="absolute inset-0 w-full h-full opacity-0 cursor-pointer" />
        <div class="pointer-events-none">
          <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 16v-6a4 4 0 014-4h1" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 3v9m0 0l-3-3m3 3 3-3" />
          </svg>
          <div class="mt-2 text-sm text-slate-600">Drop an image here or click to browse</div>
          <div class="mt-1 text-xs text-slate-400">Max recommended size: 2MB</div>
        </div>
      </div>

      <!-- URL input (hidden by default) -->
      <div id="urlRow" class="hidden">
        <label class="block text-sm font-medium text-slate-700 mb-1">Image URL</label>
        <input id="imageUrl" name="imageUrl" type="url" placeholder="https://example.com/image.jpg"
               class="w-full rounded-lg border px-4 py-2 focus:ring-2 focus:ring-green-300" />
        <div class="mt-1 text-xs text-slate-400">Paste a direct image link (must end with .jpg/.png/.webp etc.)</div>
      </div>

      <!-- preview -->
      <div class="mt-2">
        <div class="text-sm text-slate-600 mb-2">Preview</div>
        <div id="previewWrapper" class="w-full h-64 bg-white rounded-lg border flex items-center justify-center overflow-hidden">
          <img id="previewImg" src="" alt="preview" class="max-h-full max-w-full object-contain hidden" />
          <div id="previewPlaceholder" class="text-slate-400">No image selected</div>
        </div>
      </div>

      <!-- actions -->
      <div class="flex gap-3 items-center">
        <button type="submit" class="bg-green-600 hover:bg-green-700 text-white px-5 py-2 rounded-lg shadow">Create Category</button>
        <button type="button" id="clearBtn" class="bg-slate-100 px-4 py-2 rounded-lg text-slate-700">Clear</button>
        <div id="errorMsg" class="text-sm text-red-600 ml-auto hidden"></div>
      </div>
    </form>
  </div>

  <script>
    (function () {
      const fileInput = document.getElementById('fileInput');
      const imageUrl = document.getElementById('imageUrl');
      const previewImg = document.getElementById('previewImg');
      const previewPlaceholder = document.getElementById('previewPlaceholder');
      const previewWrapper = document.getElementById('previewWrapper');
      const urlRow = document.getElementById('urlRow');
      const dropArea = document.getElementById('dropArea');
      const imgModeRadios = document.querySelectorAll('input[name="imgMode"]');
      const errorMsg = document.getElementById('errorMsg');
      const clearBtn = document.getElementById('clearBtn');
      const form = document.getElementById('catForm');

      // utility
      function showPreview(src) {
        previewImg.src = src;
        previewImg.classList.remove('hidden');
        previewPlaceholder.classList.add('hidden');
      }
      function clearPreview() {
        previewImg.src = '';
        previewImg.classList.add('hidden');
        previewPlaceholder.classList.remove('hidden');
      }

      // mode toggle
      imgModeRadios.forEach(r => r.addEventListener('change', () => {
        if (r.checked) {
          if (r.value === 'url') {
            urlRow.classList.remove('hidden');
            // disable file input visually (but not remove it; server will check)
            dropArea.classList.add('opacity-60');
            clearPreview();
          } else {
            urlRow.classList.add('hidden');
            dropArea.classList.remove('opacity-60');
            imageUrl.value = '';
            clearPreview();
          }
        }
      }));

      // file input change
      fileInput.addEventListener('change', (ev) => {
        errorMsg.classList.add('hidden');
        const f = ev.target.files && ev.target.files[0];
        if (!f) { clearPreview(); return; }
        if (!f.type.startsWith('image/')) {
          errorMsg.textContent = 'Please select a valid image file.';
          errorMsg.classList.remove('hidden');
          fileInput.value = '';
          return;
        }
        // limit size (example 5MB)
        if (f.size > 5 * 1024 * 1024) {
          errorMsg.textContent = 'Image too large. Max 5MB.';
          errorMsg.classList.remove('hidden');
          fileInput.value = '';
          return;
        }
        const url = URL.createObjectURL(f);
        showPreview(url);
      });

      // drag & drop handling
      ;['dragenter','dragover'].forEach(evt => {
        dropArea.addEventListener(evt, (e) => {
          e.preventDefault(); e.stopPropagation();
          dropArea.classList.add('bg-green-50', 'border-green-200');
        });
      });
      ;['dragleave','drop'].forEach(evt => {
        dropArea.addEventListener(evt, (e) => {
          e.preventDefault(); e.stopPropagation();
          dropArea.classList.remove('bg-green-50', 'border-green-200');
        });
      });
      dropArea.addEventListener('drop', (e) => {
        const files = e.dataTransfer.files;
        if (files && files.length) {
          fileInput.files = files; // set file input
          fileInput.dispatchEvent(new Event('change'));
          // switch radio to file mode automatically
          document.querySelector('input[name="imgMode"][value="file"]').checked = true;
          urlRow.classList.add('hidden');
        }
      });

      // URL input preview
      imageUrl.addEventListener('change', () => {
        const url = imageUrl.value.trim();
        errorMsg.classList.add('hidden');
        if (!url) { clearPreview(); return; }
        // basic validation of URL extension (not bulletproof)
        if (!url.match(/\.(jpeg|jpg|gif|png|webp|svg)$/i)) {
          errorMsg.textContent = 'URL does not look like a direct image link.';
          errorMsg.classList.remove('hidden');
          return;
        }
        // set preview
        showPreview(url);
      });

      // clear button
      clearBtn.addEventListener('click', () => {
        fileInput.value = '';
        imageUrl.value = '';
        clearPreview();
        errorMsg.classList.add('hidden');
      });

      // final form submit: ensure only one source is used
      form.addEventListener('submit', (e) => {
        errorMsg.classList.add('hidden');
        const mode = document.querySelector('input[name="imgMode"]:checked').value;
        if (mode === 'file') {
          // if no file selected and no url: warn
          if (!fileInput.files || !fileInput.files.length) {
            e.preventDefault();
            errorMsg.textContent = 'Please select an image file or switch to URL mode.';
            errorMsg.classList.remove('hidden');
            return;
          }
          // keep imageUrl field empty so backend knows file is used
          imageUrl.value = '';
        } else {
          // url mode
          const url = imageUrl.value.trim();
          if (!url) {
            e.preventDefault();
            errorMsg.textContent = 'Please paste an image URL or switch to upload mode.';
            errorMsg.classList.remove('hidden');
            return;
          }
          // If URL provided, remove file selection so server receives only URL
          fileInput.value = ''; // clears selected file in many browsers
        }
      });

      // init: ensure correct initial state
      document.querySelector('input[name="imgMode"]:checked').dispatchEvent(new Event('change'));
    })();
  </script>
</body>
</html>
