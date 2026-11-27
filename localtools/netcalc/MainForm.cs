using System.Drawing;
using System.Globalization;
using System.Net;
using System.Windows.Forms;

namespace NetCalc;

internal sealed class MainForm : Form
{
    private readonly TextBox _addressInput = new();
    private readonly TextBox _prefixInput = new();
    private readonly Label _hostCount = new();
    private readonly Label _subnetDetails = new();
    private readonly Label _errorMessage = new();

    public MainForm()
    {
        Text = "NetCalc — IPv4";
        MinimumSize = new Size(480, 360);
        Size = new Size(560, 410);
        StartPosition = FormStartPosition.CenterScreen;
        AutoScaleMode = AutoScaleMode.Dpi;
        Font = new Font("Segoe UI", 10F);

        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(28),
            ColumnCount = 2,
            RowCount = 6,
        };
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 58F));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 42F));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 34F));
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 46F));
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 46F));
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 54F));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
        Controls.Add(layout);

        var heading = new Label
        {
            Text = "Количество хостов в подсети",
            AutoSize = true,
            Font = new Font(Font, FontStyle.Bold),
            Margin = new Padding(0, 0, 0, 14),
        };
        layout.Controls.Add(heading, 0, 0);
        layout.SetColumnSpan(heading, 2);

        AddField(layout, "IPv4-адрес сети", _addressInput, "192.168.0.0", 1);
        AddField(layout, "Маска CIDR", _prefixInput, "/24", 2);

        var calculateButton = new Button
        {
            Text = "Рассчитать",
            AutoSize = true,
            Anchor = AnchorStyles.Left,
            Padding = new Padding(12, 4, 12, 4),
            Margin = new Padding(0, 4, 0, 4),
        };
        calculateButton.Click += (_, _) => Calculate();
        layout.Controls.Add(calculateButton, 0, 3);
        layout.SetColumnSpan(calculateButton, 2);

        _errorMessage.AutoSize = true;
        _errorMessage.ForeColor = Color.Firebrick;
        _errorMessage.Margin = new Padding(0, 8, 0, 0);
        layout.Controls.Add(_errorMessage, 0, 4);
        layout.SetColumnSpan(_errorMessage, 2);

        var resultPanel = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 1,
            RowCount = 2,
            Margin = new Padding(0, 14, 0, 0),
        };
        resultPanel.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        resultPanel.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.Controls.Add(resultPanel, 0, 5);
        layout.SetColumnSpan(resultPanel, 2);

        var resultTitle = new Label
        {
            Text = "Доступно хостов",
            AutoSize = true,
            ForeColor = SystemColors.GrayText,
        };
        resultPanel.Controls.Add(resultTitle, 0, 0);

        var resultContent = new FlowLayoutPanel
        {
            AutoSize = true,
            Dock = DockStyle.Top,
            FlowDirection = FlowDirection.TopDown,
            WrapContents = false,
            Margin = new Padding(0, 2, 0, 0),
        };
        resultPanel.Controls.Add(resultContent, 0, 1);

        _hostCount.Text = "—";
        _hostCount.AutoSize = true;
        _hostCount.Font = new Font(Font.FontFamily, 26F, FontStyle.Bold);
        resultContent.Controls.Add(_hostCount);

        _subnetDetails.AutoSize = true;
        _subnetDetails.MaximumSize = new Size(460, 0);
        _subnetDetails.ForeColor = SystemColors.GrayText;
        resultContent.Controls.Add(_subnetDetails);

        _addressInput.KeyDown += OnInputKeyDown;
        _prefixInput.KeyDown += OnInputKeyDown;
        AcceptButton = calculateButton;
    }

    private static void AddField(
        TableLayoutPanel layout,
        string labelText,
        TextBox input,
        string initialValue,
        int row)
    {
        var label = new Label
        {
            Text = labelText,
            AutoSize = true,
            Anchor = AnchorStyles.Left,
            Margin = new Padding(0, 8, 8, 0),
        };
        input.Text = initialValue;
        input.Dock = DockStyle.Fill;
        input.Margin = new Padding(0, 4, 0, 4);
        layout.Controls.Add(label, 0, row);
        layout.Controls.Add(input, 1, row);
    }

    private void OnInputKeyDown(object? sender, KeyEventArgs e)
    {
        if (e.KeyCode == Keys.Enter)
        {
            Calculate();
            e.SuppressKeyPress = true;
        }
    }

    private void Calculate()
    {
        if (!TryParseIPv4(_addressInput.Text, out var address))
        {
            ShowError("Введите IPv4-адрес в формате, например, 192.168.0.0.");
            return;
        }

        var prefixText = _prefixInput.Text.Trim();
        if (prefixText.StartsWith("/", StringComparison.Ordinal))
        {
            prefixText = prefixText[1..];
        }

        if (!byte.TryParse(prefixText, NumberStyles.None, CultureInfo.InvariantCulture, out var prefix) ||
            prefix > 32)
        {
            ShowError("Префикс должен быть числом от 0 до 32, например /24.");
            return;
        }

        var addressBytes = address.GetAddressBytes();
        var addressValue = ((uint)addressBytes[0] << 24) |
                           ((uint)addressBytes[1] << 16) |
                           ((uint)addressBytes[2] << 8) |
                           addressBytes[3];
        var subnetMask = prefix == 0 ? 0u : uint.MaxValue << (32 - prefix);
        var networkValue = addressValue & subnetMask;
        var broadcastValue = networkValue | ~subnetMask;
        var totalAddresses = 1L << (32 - prefix);
        var usableHosts = prefix switch
        {
            <= 30 => totalAddresses - 2,
            31 => 2,
            _ => 1,
        };

        _hostCount.Text = usableHosts.ToString("N0", CultureInfo.CurrentCulture);
        _subnetDetails.Text =
            $"{totalAddresses.ToString("N0", CultureInfo.CurrentCulture)} адресов · " +
            $"сеть {FormatIPv4(networkValue)} · broadcast {FormatIPv4(broadcastValue)}";
        _errorMessage.Text = string.Empty;
    }

    private void ShowError(string message)
    {
        _hostCount.Text = "—";
        _subnetDetails.Text = string.Empty;
        _errorMessage.Text = message;
    }

    private static bool TryParseIPv4(string input, out IPAddress address)
    {
        address = IPAddress.None;
        var octets = input.Trim().Split('.');
        if (octets.Length != 4)
        {
            return false;
        }

        var addressBytes = new byte[4];
        for (var index = 0; index < octets.Length; index++)
        {
            if (!byte.TryParse(
                    octets[index],
                    NumberStyles.None,
                    CultureInfo.InvariantCulture,
                    out addressBytes[index]))
            {
                return false;
            }
        }

        address = new IPAddress(addressBytes);
        return true;
    }

    private static string FormatIPv4(uint address)
    {
        return string.Join(
            ".",
            (address >> 24) & 0xFF,
            (address >> 16) & 0xFF,
            (address >> 8) & 0xFF,
            address & 0xFF);
    }
}
