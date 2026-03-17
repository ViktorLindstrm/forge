defmodule Forge.Storage do
  @upload_dir "priv/static/uploads"

  @spec store(String.t(), binary()) :: {:ok, String.t()} | {:error, term()}
  def store(filename, content) do
    dir = Path.join(File.cwd!(), @upload_dir)
    File.mkdir_p!(dir)
    case File.write(Path.join(dir, filename), content) do
      :ok  -> {:ok, "#{@upload_dir}/#{filename}"}
      err  -> err
    end
  end

  @spec url(String.t()) :: String.t()
  def url(storage_path) do
    "/" <> String.replace_prefix(storage_path, "priv/static/", "")
  end

  @spec delete(String.t()) :: :ok | {:error, term()}
  def delete(storage_path) do
    path = Path.join(File.cwd!(), storage_path)
    case File.rm(path) do
      :ok               -> :ok
      {:error, :enoent} -> :ok
      err               -> err
    end
  end

  @spec unique_filename(String.t()) :: String.t()
  def unique_filename(original) do
    ext  = Path.extname(original)
    base = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    "#{base}#{ext}"
  end
end
