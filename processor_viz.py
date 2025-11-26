import tkinter as tk
from tkinter import ttk
import os

# Configuration
LOG_DIR = "sim/logs"
REG_FILE = os.path.join(LOG_DIR, "register_content.txt")
MEM_FILE = os.path.join(LOG_DIR, "memory_content.txt")
PC_LOG_FILE = os.path.join(LOG_DIR, "PC_log.txt")

# --- Modern Violet Theme Palette ---
COLORS = {
    "bg_main": "#F3F0F7",  # Light gray-violet background
    "bg_panel": "#FFFFFF",  # White for panels
    "primary": "#6A1B9A",  # Deep Violet (Headers, Accents)
    "secondary": "#9C27B0",  # Lighter Violet (Buttons, Highlights)
    "accent": "#E1BEE7",  # Pale Violet (Active Memory/Regs)
    "text_dark": "#2D2D2D",  # Dark text
    "text_light": "#FFFFFF",  # Light text
    "highlight_pc": "#D1C4E9",  # Color for current PC instruction
    "highlight_mem": "#B39DDB",  # Color for modified memory
}


class ProcessorViz(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("16-Bit RISC Processor Visualization")
        self.geometry("1100x700")
        self.configure(bg=COLORS["bg_main"])

        # Data Stores
        self.reg_vars = {}
        self.mem_labels = []
        self.auto_refresh = False

        # --- Custom Style Setup ---
        style = ttk.Style()
        style.theme_use("clam")

        # Configure Colors & Fonts
        style.configure("TFrame", background=COLORS["bg_main"])
        style.configure("Panel.TFrame", background=COLORS["bg_panel"])

        style.configure("TLabelFrame", background=COLORS["bg_panel"], relief="flat")
        style.configure(
            "TLabelFrame.Label",
            background=COLORS["bg_panel"],
            foreground=COLORS["primary"],
            font=("Segoe UI", 11, "bold"),
        )

        style.configure(
            "TLabel",
            background=COLORS["bg_panel"],
            foreground=COLORS["text_dark"],
            font=("Consolas", 10),
        )
        style.configure(
            "Header.TLabel",
            background=COLORS["bg_panel"],
            foreground=COLORS["primary"],
            font=("Segoe UI", 10, "bold"),
        )

        # Button Styling
        style.configure(
            "TButton",
            background=COLORS["primary"],
            foreground=COLORS["text_light"],
            borderwidth=0,
            font=("Segoe UI", 10),
        )
        style.map("TButton", background=[("active", COLORS["secondary"])])

        # --- UI Layout ---

        # Main container
        main_frame = ttk.Frame(self)
        main_frame.pack(fill="both", expand=True, padx=20, pady=20)

        # --- Left Panel: Registers & PC ---
        left_panel = ttk.Frame(main_frame, width=280)
        left_panel.pack(side="left", fill="y", padx=(0, 15))

        # Registers Section
        reg_frame = ttk.LabelFrame(left_panel, text="Register File", padding=15)
        reg_frame.pack(fill="x", pady=(0, 15))

        for i in range(8):
            row = ttk.Frame(reg_frame, style="Panel.TFrame")
            row.pack(fill="x", pady=3)

            # Register Label
            ttk.Label(
                row,
                text=f"R{i}:",
                width=4,
                font=("Consolas", 12, "bold"),
                foreground=COLORS["primary"],
            ).pack(side="left")

            # Register Value Box
            var = tk.StringVar(value="0000")
            self.reg_vars[i] = var
            val_lbl = tk.Label(
                row,
                textvariable=var,
                bg="#F5F5F5",
                fg="#333",
                relief="flat",
                width=12,
                font=("Consolas", 12),
                padx=5,
                pady=2,
            )
            val_lbl.pack(side="left", fill="x", expand=True)

        # PC Display Section
        self.pc_var = tk.StringVar(value="00")
        pc_frame = ttk.LabelFrame(left_panel, text="Program Counter", padding=15)
        pc_frame.pack(fill="x", pady=(0, 15))

        pc_val = tk.Label(
            pc_frame,
            textvariable=self.pc_var,
            font=("Consolas", 24, "bold"),
            bg=COLORS["bg_panel"],
            fg=COLORS["secondary"],
        )
        pc_val.pack(anchor="center")

        # Controls Section
        ctrl_frame = ttk.Frame(left_panel)
        ctrl_frame.pack(fill="x")
        ttk.Button(ctrl_frame, text="Refresh Data", command=self.load_data).pack(
            fill="x", pady=5
        )

        # --- Right Panel: Memory Grid ---
        mem_frame_cont = ttk.LabelFrame(
            main_frame, text="Memory Map (256 Words)", padding=10
        )
        mem_frame_cont.pack(side="right", fill="both", expand=True)

        # Custom Canvas for Memory
        self.canvas = tk.Canvas(
            mem_frame_cont, bg=COLORS["bg_panel"], highlightthickness=0
        )
        scrollbar = ttk.Scrollbar(
            mem_frame_cont, orient="vertical", command=self.canvas.yview
        )
        self.scrollable_frame = ttk.Frame(self.canvas, style="Panel.TFrame")

        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")),
        )
        self.frame_id = self.canvas.create_window(
            (0, 0), window=self.scrollable_frame, anchor="nw"
        )
        self.canvas.bind("<Configure>", self.on_canvas_resize)
        self.canvas.configure(yscrollcommand=scrollbar.set)

        self.canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        # Init Grid
        self.create_memory_grid()

        # Initial Load
        self.load_data()

    def create_memory_grid(self):
        cols = 8
        for c in range(cols):
            self.scrollable_frame.columnconfigure(c, weight=1, uniform="mem")

        # Header Row
        header = ttk.Frame(self.scrollable_frame, style="Panel.TFrame")
        header.grid(row=0, column=0, columnspan=cols, sticky="ew", pady=(0, 10))

        # Create header columns
        for c in range(cols):
            col_head = ttk.Frame(self.scrollable_frame, style="Panel.TFrame")
            col_head.grid(row=0, column=c, sticky="ew")
            ttk.Label(
                col_head, text=f"+{c:X}", style="Header.TLabel", justify="center"
            ).pack()

        for i in range(256):
            row = (i // cols) + 1
            col = i % cols

            # Memory Cell Frame
            f = tk.Frame(self.scrollable_frame, bg=COLORS["bg_panel"], bd=0)
            f.grid(row=row, column=col, padx=1, pady=1, sticky="ew")

            # Address Label (Tiny)
            tk.Label(
                f,
                text=f"[{i:02X}]",
                font=("Consolas", 8),
                fg="#999",
                bg=COLORS["bg_panel"],
            ).pack(anchor="w", padx=2)

            # Data Value Label
            lbl = tk.Label(
                f,
                text="0000",
                font=("Consolas", 11),
                bg="#F0F0F0",
                fg="#444",
                width=6,
                pady=4,
            )
            lbl.pack(fill="x", padx=2, pady=(0, 2))
            self.mem_labels.append(lbl)

    def on_canvas_resize(self, event):
        self.canvas.itemconfig(self.frame_id, width=event.width)

    def load_data(self):
        # Load Registers
        try:
            if os.path.exists(REG_FILE):
                with open(REG_FILE, "r") as f:
                    lines = f.readlines()
                    for line in lines:
                        parts = line.strip().split(":")
                        if len(parts) == 2:
                            reg_idx = int(parts[0].replace("R", ""))
                            val = parts[1].strip()
                            if reg_idx in self.reg_vars:
                                self.reg_vars[reg_idx].set(val)
        except Exception as e:
            print(f"Error loading registers: {e}")

        # Load Memory
        try:
            if os.path.exists(MEM_FILE):
                with open(MEM_FILE, "r") as f:
                    lines = f.readlines()
                    for line in lines:
                        parts = line.strip().split(":")
                        if len(parts) == 2:
                            addr = int(parts[0], 10)
                            val = parts[1].strip()

                            if 0 <= addr < 256:
                                lbl = self.mem_labels[addr]
                                lbl.config(text=val)

                                if val != "xxxx" and val != "0000":
                                    lbl.config(bg=COLORS["highlight_mem"], fg="white")
                                else:
                                    lbl.config(bg="#F0F0F0", fg="#444")
        except Exception as e:
            print(f"Error loading memory: {e}")

        # Load PC
        try:
            if os.path.exists(PC_LOG_FILE):
                with open(PC_LOG_FILE, "r") as f:
                    lines = f.readlines()
                    if lines:
                        last_line = lines[-1]
                        if "Current Addr" in last_line:
                            try:
                                curr_addr_hex = last_line.split("Current Addr:")[
                                    1
                                ].strip()
                                self.pc_var.set(f"0x{curr_addr_hex}")

                                # Highlight PC
                                pc_int = int(curr_addr_hex, 16)
                                # Clear previous highlights (simple reload)
                                # Since we reload all mem cells above, just highlight current
                                if 0 <= pc_int < 256:
                                    self.mem_labels[pc_int].config(
                                        bg=COLORS["highlight_pc"], fg="#000"
                                    )
                            except:
                                pass
        except Exception as e:
            print(f"Error loading PC: {e}")

        if self.auto_refresh:
            self.after(1000, self.load_data)

    def toggle_auto_refresh(self):
        self.auto_refresh = not self.auto_refresh
        if self.auto_refresh:
            self.load_data()


if __name__ == "__main__":
    if not os.path.exists(LOG_DIR):
        try:
            os.makedirs(LOG_DIR)
        except:
            pass
    app = ProcessorViz()
    app.mainloop()
