import tkinter as tk
from tkinter import ttk, messagebox
import os

# Configuration
LOG_DIR = "sim/logs"
REG_FILE = os.path.join(LOG_DIR, "register_content.txt")
MEM_FILE = os.path.join(LOG_DIR, "memory_content.txt")
PC_LOG_FILE = os.path.join(LOG_DIR, "PC_log.txt")


class ProcessorViz(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("16-Bit RISC Processor Visualization")
        self.geometry("1000x650")  # Made slightly larger
        self.configure(bg="#f0f0f0")

        # --- Style ---
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("TLabel", background="#f0f0f0", font=("Consolas", 10))
        style.configure("Header.TLabel", font=("Arial", 12, "bold"), foreground="#333")
        style.configure("Value.TLabel", background="white", relief="solid", padding=5)

        # --- Main Layout ---
        # Left: Registers & PC
        # Right: Memory Grid
        main_frame = ttk.Frame(self)
        main_frame.pack(fill="both", expand=True, padx=10, pady=10)

        # Left Panel
        left_panel = ttk.Frame(main_frame)
        left_panel.pack(side="left", fill="y", padx=(0, 20))

        # Registers Frame
        reg_frame = ttk.LabelFrame(left_panel, text="Register File", padding=10)
        reg_frame.pack(fill="x", pady=(0, 20))

        self.reg_vars = {}
        for i in range(8):
            row = ttk.Frame(reg_frame)
            row.pack(fill="x", pady=2)

            lbl = ttk.Label(row, text=f"R{i}:", width=4, font=("Consolas", 12, "bold"))
            lbl.pack(side="left")

            val_var = tk.StringVar(value="0000")
            self.reg_vars[i] = val_var

            val_lbl = ttk.Label(
                row,
                textvariable=val_var,
                style="Value.TLabel",
                width=10,
                font=("Consolas", 12),
            )
            val_lbl.pack(side="left", fill="x", expand=True)

        # PC Status Frame
        pc_frame = ttk.LabelFrame(left_panel, text="Processor Status", padding=10)
        pc_frame.pack(fill="x")

        self.pc_var = tk.StringVar(value="00")
        ttk.Label(pc_frame, text="Current PC:").pack(anchor="w")
        ttk.Label(
            pc_frame,
            textvariable=self.pc_var,
            font=("Consolas", 14, "bold"),
            foreground="blue",
        ).pack(anchor="w")

        # Controls
        btn_frame = ttk.Frame(left_panel)
        btn_frame.pack(fill="x", pady=20)
        ttk.Button(btn_frame, text="Refresh Data", command=self.load_data).pack(
            fill="x", pady=5
        )
        ttk.Button(
            btn_frame, text="Auto-Refresh (1s)", command=self.toggle_auto_refresh
        ).pack(fill="x", pady=5)

        # Right Panel (Memory)
        mem_frame_container = ttk.LabelFrame(
            main_frame, text="Memory Map (256 Words)", padding=10
        )
        mem_frame_container.pack(side="right", fill="both", expand=True)

        # Canvas for scrolling
        self.canvas = tk.Canvas(mem_frame_container, bg="white")
        scrollbar = ttk.Scrollbar(
            mem_frame_container, orient="vertical", command=self.canvas.yview
        )
        self.scrollable_frame = ttk.Frame(self.canvas)

        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")),
        )

        # FIX 1: Capture the Window ID created on the canvas
        self.frame_id = self.canvas.create_window(
            (0, 0), window=self.scrollable_frame, anchor="nw"
        )

        # FIX 2: Bind the canvas configuration event to resize the inner frame
        self.canvas.bind("<Configure>", self.on_canvas_configure)

        self.canvas.configure(yscrollcommand=scrollbar.set)

        self.canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        # Initialize Memory Grid
        self.mem_labels = []
        self.create_memory_grid()

        # Auto-refresh state
        self.auto_refresh = False

        # Initial Load
        self.load_data()

    # FIX 3: The method that forces the frame to fill the canvas width
    def on_canvas_configure(self, event):
        self.canvas.itemconfig(self.frame_id, width=event.width)

    # ... inside ProcessorViz class ...

    def create_memory_grid(self):
        # Change to 8 columns for a denser, wider layout
        num_columns = 8

        # Configure grid columns to expand evenly
        for col in range(num_columns):
            # 'uniform' group makes sure all columns are exactly the same width
            self.scrollable_frame.columnconfigure(col, weight=1, uniform="mem_cols")

        # Header row
        headers = ttk.Frame(self.scrollable_frame)
        headers.grid(row=0, column=0, columnspan=num_columns, sticky="ew", pady=(0, 10))

        # Simple header label
        ttk.Label(
            headers, text=f"Memory Map ({num_columns} Cols)", font=("Arial", 10, "bold")
        ).pack(side="left", padx=5)

        for i in range(256):
            # Calculate row and column for 8-column grid
            row = (i // num_columns) + 1
            col = i % num_columns

            lbl_frame = ttk.Frame(self.scrollable_frame, relief="flat", borderwidth=1)
            # sticky="ew" ensures they stretch to touch each other
            lbl_frame.grid(row=row, column=col, padx=1, pady=1, sticky="ew")

            # Address Label (Smaller, gray)
            addr_lbl = tk.Label(
                lbl_frame, text=f"[{i:02X}]", font=("Consolas", 8), fg="#888"
            )
            addr_lbl.pack(side="top", anchor="w", padx=2)

            # Value Label (Bold, center)
            val_lbl = tk.Label(
                lbl_frame,
                text="0000",
                font=("Consolas", 10, "bold"),
                bg="#eee",
                width=6,
            )
            val_lbl.pack(side="top", fill="x", padx=2, pady=(0, 2))

            self.mem_labels.append(val_lbl)

    def load_data(self):
        # Load Registers
        try:
            if os.path.exists(REG_FILE):
                with open(REG_FILE, "r") as f:
                    lines = f.readlines()
                    for line in lines:
                        # Expected format: "R0: 0000"
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
                    # Format: "00: 5205"
                    for line in lines:
                        parts = line.strip().split(":")
                        if len(parts) == 2:
                            addr = int(
                                parts[0], 10
                            )  # Your file uses decimal address "00", "01"
                            val = parts[1].strip()

                            if 0 <= addr < 256:
                                # Update visual
                                lbl = self.mem_labels[addr]
                                lbl.config(text=val)

                                # Highlight non-zero/instruction code differently
                                if val != "xxxx" and val != "0000":
                                    lbl.config(
                                        bg="#d1e7dd", fg="#0f5132"
                                    )  # Greenish for active data
                                else:
                                    lbl.config(bg="#eee", fg="black")
        except Exception as e:
            print(f"Error loading memory: {e}")

        # Load PC (Last entry)
        try:
            if os.path.exists(PC_LOG_FILE):
                with open(PC_LOG_FILE, "r") as f:
                    lines = f.readlines()
                    if lines:
                        last_line = lines[-1]
                        # Format: "Time: 50 ns | Next Addr: 04 | Current Addr: 01"
                        if "Current Addr" in last_line:
                            try:
                                curr_addr_hex = last_line.split("Current Addr:")[
                                    1
                                ].strip()
                                self.pc_var.set(f"0x{curr_addr_hex}")

                                # Highlight the current instruction memory cell
                                pc_int = int(curr_addr_hex, 16)
                                if 0 <= pc_int < 256:
                                    self.mem_labels[pc_int].config(
                                        bg="#ffc107", fg="black"
                                    )  # Yellow highlight
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
            # Create dummy files so it doesn't crash on first run
            with open(REG_FILE, "w") as f:
                f.write("R0: 0000")
            with open(MEM_FILE, "w") as f:
                f.write("00: 0000")
        except:
            pass

    app = ProcessorViz()
    app.mainloop()
